require 'rubygems'
require 'active_support'
require 'active_support/inflector/inflections'
module RHapi
  
  class Lead
    
    attr_accessor :attributes, :changed_attributes
    
    def initialize(data)
      self.attributes = data
      self.changed_attributes = {}
    end
    
    # Class methods ----------------------------------------------------------
    def self.find(search=nil)
      data = Curl::Easy.perform("#{RHapi.options[:end_point]}/leads/#{RHapi.options[:version]}/list?hapikey=#{RHapi.options[:api_key]}&search=#{search}")
      RHapi::RHapiException.raise_error(data.body_str) if data.body_str =~ /Error/i
      lead_data = JSON.parse(data.body_str)
      leads = []
      lead_data.each do |data|
        lead = Lead.new(data)
        leads << lead
      end
      leads
    end
    
    def self.find_by_guid(guid)
      url = "#{RHapi.options[:end_point]}/leads/#{RHapi.options[:version]}/lead/#{guid}?hapikey=#{RHapi.options[:api_key]}"
      c = Curl::Easy.perform(url)
      RHapi::RHapiException.raise_error(c.body_str) if c.body_str =~ /Error/i
      lead_data = JSON.parse(c.body_str)
      Lead.new(lead_data)
    end
    
    # Instance methods -------------------------------------------------------
    def update
      url = "#{RHapi.options[:end_point]}/leads/#{RHapi.options[:version]}/lead/#{self.guid}?hapikey=#{RHapi.options[:api_key]}"
      data = self.changed_attributes.to_json
      c = Curl::Easy.http_put(url, data) do |curl| 
        curl.headers["Content-Type"] = "application/json"
        curl.header_in_body = true
      end
      RHapi::RHapiException.raise_error(c.body_str) unless c.body_str =~ /200/i
      true
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