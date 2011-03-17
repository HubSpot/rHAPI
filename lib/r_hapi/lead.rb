require 'rubygems'
require 'active_support'
require 'active_support/inflector/inflections'
module RHapi
  
  class Lead
    
    attr_accessor :data
    
    def self.find(search=nil)
      data = Curl::Easy.perform("#{RHapi.options[:end_point]}/leads/v1/list?hapikey=#{RHapi.options[:api_key]}&search=#{search}")
      lead_data = JSON.parse(data.body_str)
      leads = []
      lead_data.each do |data|
        lead = Lead.new
        lead.data = data
        #puts data.inspect
        leads << lead
      end
      leads
    end
    
    # Work with data in the data hash
    def method_missing(method, *args, &block)
      
      method_name = ActiveSupport::Inflector.camelize(method.to_s, false)
      if method_name[-1..-1] == "="
        method_name = method_name[0..method_name.length-1]
        # set the value
        self.data[method_name] = args[0]
      end 
      
      return super unless self.data.include?(method_name)
      self.data[method_name]
    end
    
  end
  
end