require 'rubygems'
require 'active_support'
require 'active_support/inflector/inflections'
require File.expand_path('../connection', __FILE__)

module RHapi
  class PortalStatistic
    include Connection
    extend Connection::ClassMethods

    attr_reader :attributes

    def initialize(data)
      @attributes = data
    end

    # Instance methods -------------------------------------------------------
    # Work with data in the data hash
    def method_missing(method, *args, &block)
      
      attribute = ActiveSupport::Inflector.camelize(method.to_s, false)
  
      return super unless self.attributes.include?(attribute)
      self.attributes[attribute]
            
    end
  end

  class ContactQuery
    include Connection
    extend Connection::ClassMethods
    
    attr_accessor :attributes, :changed_attributes
    
    def initialize(data)

      contacts = []
      data['contacts'].each do |data|
        contact = Contact.new(data)
        contacts << contact
      end
      data['contacts'] = contacts      
      self.attributes = data
      self.changed_attributes = {}
    end

    # Instance methods -------------------------------------------------------
    # Refresh the query
    def refresh_query(search=nil, options={})  
      options[:q] = search unless search.nil?
      options[:q] = @changed_attributes['query'] unless @changed_attributes['query'].nil?
      options[:count] = @changed_attributes['offset'] unless @changed_attributes['offset'].nil?
      results = Contact.find(search, options)
      results.attributes.each_pair do |key, value|
        self.attributes[key] = value
      end
      self.changed_attributes = {}
      true
    end
    # Work with data in the data hash
    def method_missing(method, *args, &block)
      
      attribute = ActiveSupport::Inflector.camelize(method.to_s, false)
      dashed_attribute = ActiveSupport::Inflector.dasherize(ActiveSupport::Inflector.underscore(attribute))
  
      if dashed_attribute =~ /=$/
        dashed_attribute = dashed_attribute.chop
        return super unless self.attributes.include?("#{dashed_attribute}")
        self.changed_attributes["#{dashed_attribute}"] = args[0]
        self.attributes["#{dashed_attribute}"] = args[0]
      else
        return super unless self.attributes.include?("#{dashed_attribute}")
        self.attributes["#{dashed_attribute}"]
      end 
            
    end

  end

  class ContactProperty
    include Connection
    extend Connection::ClassMethods
    
    attr_accessor :attributes, :changed_attributes
    
    def initialize(data)
      data.each do |property, hash|
        data[property] = hash["value"]
      end
      
      self.attributes = data
      self.changed_attributes = {}
    end

    # Instance methods -------------------------------------------------------
    # Work with data in the data hash
    def method_missing(method, *args, &block)
      
      attribute = ActiveSupport::Inflector.camelize(method.to_s, false)
  
      if attribute =~ /=$/
        attribute = attribute.chop
        return super unless self.attributes.include?(attribute)
        self.changed_attributes[attribute] = args[0]
        self.attributes[attribute] = args[0]
      else
        return super unless self.attributes.include?(attribute)
        self.attributes[attribute]
      end 
            
    end

  end

  class Contact
    include Connection
    extend Connection::ClassMethods
    
    attr_accessor :attributes, :changed_attributes # reference changes from nested object
    attr_reader :read_only_members
    
    def initialize(data)
      @read_only_members = data.slice!('properties') # Construct read-only attributes (e.g.: portal id)
      data['properties'] = ContactProperty.new(data['properties'])
      self.attributes = data # Read-writable properties (e.g.: first & last name)
      self.changed_attributes = {}
    end
    
    # Class methods ----------------------------------------------------------
    
    # Finds contacts and returns an array of contacts. 
    # An optional string value that is used to search several basic contact fields: first name, last name, email address, 
    # and company name. According to HubSpot docs, a more advanced search is coming in the future. 
    # The default value for is nil, meaning return all contact.
    def self.find(search=nil, options={})  
      options[:q] = search unless search.nil?
      response = get(url_for({
        :api => 'contacts',
        :resource => 'search',
        :method => 'query'
      }, options))
 
      contact_data = JSON.parse(response.body_str)
      ContactQuery.new(contact_data)
    end
    
    # Finds specified contact by its unique id (vid).
    def self.find_by_vid(vid)
      response = get(url_for(
        :api => 'contacts',
        :resource => 'contact',
        :filter => 'vid',
        :identifier => vid,
        :method => 'profile'
      ))
      contact_data = JSON.parse(response.body_str)
      Contact.new(contact_data)
    end

    # Finds specified contact by its email address.
    def self.find_by_email(email)
      response = get(url_for(
        :api => 'contacts',
        :resource => 'contact',
        :filter => 'email',
        :identifier => email,
        :method => 'profile'
      ))
      contact_data = JSON.parse(response.body_str)
      Contact.new(contact_data)
    end

    # Finds specified contact by its user token.
    def self.find_by_token(token)
      response = get(url_for(
        :api => 'contacts',
        :resource => 'contact',
        :filter => 'utk',
        :identifier => token,
        :method => 'profile'
      ))
      contact_data = JSON.parse(response.body_str)
      Contact.new(contact_data)
    end

    # Gets portal statistics.
    def self.statistics
      response = get(url_for(
        :api => 'contacts',
        :resource => 'contacts',
        :method => 'statistics'
      ))
      statistics_data = JSON.parse(response.body_str)
      PortalStatistic.new(statistics_data)
    end
    
    # Instance methods -------------------------------------------------------
    def update(params={})
      update_attributes(params) unless params.empty?
      response = put(Contact.url_for(
        :api => 'contacts',
        :resource => 'contact',
        :identifier => self.guid,
      ), self.changed_attributes)
      true
    end
    
    def update_attributes(params)
      raise(RHapi::AttributeError, "The params must be a hash.") unless params.is_a?(Hash)
      params.each do |key, value|
        attribute = ActiveSupport::Inflector.camelize(key.to_s, false)
        raise(RHapi::AttributeError, "No Hubspot attribute with the name #{attribute}.") unless self.attributes.include?(attribute)
        self.changed_attributes[attribute] = value
        self.attributes[attribute] = value
      end
    end
    
    
    
    # Work with data in the data hash
    def method_missing(method, *args, &block)
      
      attribute = ActiveSupport::Inflector.camelize(method.to_s, false)
      dashed_attribute = ActiveSupport::Inflector.dasherize(ActiveSupport::Inflector.underscore(attribute))
  
      if attribute =~ /=$/ # Handle assignments only for read-writable attributes
        attribute = attribute.chop
        return super unless self.attributes.include?(attribute)
        self.changed_attributes[attribute] = args[0]
        self.attributes[attribute] = args[0]
      elsif self.attributes.include?(attribute) # Accessor for existing attributes
        self.attributes[attribute]
      elsif self.read_only_members.include?("#{dashed_attribute}") # Accessor for existing read-only members
        self.read_only_members["#{dashed_attribute}"]
      else # Not found - use default behavior
        super
      end 
            
    end
    
  end
  
end
