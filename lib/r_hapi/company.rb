require 'rubygems'
require 'active_support'
require 'active_support/inflector/inflections'
require 'active_support/core_ext/hash/slice'
require File.expand_path('../connection', __FILE__)

module RHapi
  class CompanyProperty
    include Connection
    extend Connection::ClassMethods

    attr_accessor :attributes, :changed_attributes

    def initialize(data=nil)
      unless data.nil?
        data.each do |property, hash|
          data[property] = hash["value"]
        end

        self.attributes = data
      else
        self.attributes = {}
      end
      self.changed_attributes = {}
    end

    # Instance methods -------------------------------------------------------
    # Work with data in the data hash
    def method_missing(method, *args, &block)
      attribute = method.to_s

      if attribute =~ /=$/ # Define property -- does not have to exist
        attribute = attribute.chop
        self.changed_attributes[attribute] = args[0]
        self.attributes[attribute] = args[0]
      else
        return super unless self.attributes.include?(attribute)
        self.attributes[attribute]
      end 

    end

  end

  class Company
    include Connection
    extend Connection::ClassMethods

    attr_accessor :properties
    attr_reader :read_only_members

    def initialize(data={})
      self.properties = CompanyProperty.new(data['properties'])
      @read_only_members = data.slice!('properties') # Construct read-only attributes (e.g.: portal id)
    end

    # Class methods ----------------------------------------------------------

    def self.create(params)
      company = Company.new
      company.update_attributes(params)
      # returns new company object # TODO: ensure returns company object
    end

    # Finds specified company by its unique id (companyId).
    def self.find_by_company_id(company_id)
      response = get(url_for(
        :version => 'v2',
        :api => 'companies',
        :resource => 'companies',
        :identifier => company_id
      ))
      company_data = JSON.parse(response.body_str)
      Company.new(company_data)
    end

    class << self
    end

    # Instance methods -------------------------------------------------------
    def save
      params = []
      self.properties.changed_attributes.each_pair do |key, value|
        params << { :name => key, :value => value }
      end
      params = { 'properties' => params }
      # call create or update API method accordingly
      if self.read_only_members.empty?
        response = create_new(params)
      else
        response = update_existing(params)
      end
      self.properties.changed_attributes = {}
      response
    end

    def update(params={})
      unless params.empty?
        update_attributes(params) # changes values and sets changed_attributes for CompanyProperty object
        # at self.properties[.{changed_}attributes], then runs save
      else 
        save
      end
    end

    # Note: Takes the exact string name of the property to be changed
    # TODO: only allow existing properties
    def update_attribute(name, value) # to be deprecated in rails 4 by update_column
      self.properties.send(name.to_s + '=', value)
      save
    end

    # Note: Takes the exact string name of the property to be changed
    # TODO: only allow existing properties
    def update_attributes(params)
      raise(RHapi::AttributeError, "The params must be a hash.") unless params.is_a?(Hash)
      params.each do |name, value|
        self.properties.send(name.to_s + '=', value)
      end
      save # only call API once rather than repeatedly saving with update_attribute calls
    end

    def create_new(params)
      response = post(Company.url_for(
        :version => 'v2',
        :api => 'companies',
        :resource => 'companies'
      ), params)
      company_data = JSON.parse(response.body_str)
      Company.new(company_data)
    end

    def update_existing(params)
      response = put(Company.url_for(
        :version => 'v2',
        :api => 'companies',
        :resource => 'companies',
        :identifier => self.company_id
      ), params)
      true
    end

    def delete
      response = http_delete(Company.url_for(
        :version => 'v2',
        :api => 'companies',
        :resource => 'companies',
        :identifier => self.company_id
      ))
      true
    end

    alias_method :destroy, :delete

    # Work with data in the data hash
    def method_missing(method, *args, &block)

      attribute = ActiveSupport::Inflector.camelize(method.to_s, false)
      dashed_attribute = ActiveSupport::Inflector.dasherize(ActiveSupport::Inflector.underscore(attribute))

      if self.read_only_members.include?("#{dashed_attribute}") # Accessor for existing read-only members
        self.read_only_members["#{dashed_attribute}"]
      elsif self.read_only_members.include?("#{attribute}") # Accessor for existing read-only members
        self.read_only_members["#{attribute}"]
      else # Not found - use default behavior
        self.properties.send(method, args, block)
      end

    end

    private :create_new
    private :update_existing
  end
end
