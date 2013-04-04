require 'rubygems'
require 'active_support'
require 'active_support/inflector/inflections'
require 'ostruct'
require File.expand_path('../connection', __FILE__)

module RHapi
  
  class Lead
    include Connection
    extend Connection::ClassMethods
    
    attr_accessor :attributes, :changed_attributes
    
    def initialize(data)
      self.attributes = data
      self.changed_attributes = {}
    end
    
    # Class methods ----------------------------------------------------------
    
    # Finds leads and returns an array of leads. 
    # An optional string value that is used to search several basic lead fields: first name, last name, email address, 
    # and company name. According to HubSpot docs, a more advanced search is coming in the future. 
    # The default value for is nil, meaning return all leads.
    def self.find(search=nil, options={})  
      options[:search] = search unless search.nil?
      response = get(url_for({
        :api => 'leads',
        :method => 'list'
      }, options))
 
      lead_data = JSON.parse(response.body_str)
      leads = []
      lead_data.each do |data|
        lead = Lead.new(data)
        leads << lead
      end
      leads
    end
    
    # Finds specified lead by the guid.
    def self.find_by_guid(guid)
      response = get(url_for(
        :api => 'leads',
        :resource => 'lead',
        :identifier => guid
      ))
      lead_data = JSON.parse(response.body_str)
      Lead.new(lead_data)
    end
    
    # Instance methods -------------------------------------------------------
    def update(params={})
      update_attributes(params) unless params.empty?
      response = put(Lead.url_for(
        :api => 'leads',
        :resource => 'lead',
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
  
end
