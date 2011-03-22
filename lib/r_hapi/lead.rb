require 'rubygems'
require 'active_support'
require 'active_support/inflector/inflections'
require File.expand_path('../connection', __FILE__)

module RHapi
  
  class Lead
    extend Connection
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
      response = get(url_for("list", nil, options))
 
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
      response = get(url_for("lead", guid))
      lead_data = JSON.parse(response.body_str)
      Lead.new(lead_data)
    end
    
    # Instance methods -------------------------------------------------------
    def update
      # url = "#{RHapi.options[:end_point]}/leads/#{RHapi.options[:version]}/lead/#{self.guid}?hapikey=#{RHapi.options[:api_key]}"
      # data = self.changed_attributes.to_json
      # response = Curl::Easy.http_put(url, data) do |curl| 
      #   curl.headers["Content-Type"] = "application/json"
      #   curl.header_in_body = true
      #   curl.on_failure do |response, err|
      #     RHapi::ConnectionError.raise_error("#{response.response_code}\n Error is: #{err.inspect}")
      #   end
      # end
      # RHapi::ConnectionError.raise_error(response.body_str) unless response.body_str =~ /2\d\d/
      response = Lead.put(Lead.url_for("lead", self.guid), self.changed_attributes)
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