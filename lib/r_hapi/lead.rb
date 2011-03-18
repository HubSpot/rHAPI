require 'rubygems'
require 'active_support'
require 'active_support/inflector/inflections'
module RHapi
  
  class Lead
    
    attr_accessor :attributes
    
    def initialize(data)
      self.attributes = data
    end
    
    def self.find(search=nil)
      data = Curl::Easy.perform("#{RHapi.options[:end_point]}/leads/v1/list?hapikey=#{RHapi.options[:api_key]}&search=#{search}")
      raise(RHapi::RHapiException.new(data.body_str), RHapi::RHapiException.new(data.body_str).message) if data.body_str =~ /Error/i
      lead_data = JSON.parse(data.body_str)
      leads = []
      lead_data.each do |data|
        lead = Lead.new(data)
        leads << lead
      end
      leads
    end
    
    # Work with data in the data hash
    def method_missing(method, *args, &block)
      
      attribute = ActiveSupport::Inflector.camelize(method.to_s, false)
  
      if attribute =~ /=$/
        attribute = attribute.chop
        return super unless self.attributes.include?(attribute)
        self.attributes[attribute] = args[0]
      else
        return super unless self.attributes.include?(attribute)
        self.attributes[attribute]
      end 
            
    end
    
  end
  
end