require 'curb'
require 'json'
module RHapi
  module Connection
    
    # Instance methods ---------------------------------------------------------------------------  
      
    def put(url, payload)
      data = payload.to_json
      response = Curl::Easy.http_put(url, data) do |curl| 
        curl.headers["Content-Type"] = "application/json"
        curl.on_failure do |response, err|
          RHapi::ConnectionError.raise_error("#{response.response_code}\n Error is: #{err.inspect}")
        end
      end
      RHapi::ConnectionError.raise_error(response.header_str) unless response.header_str =~ /2\d\d/
    end
    
    # Class methods -----------------------------------------------------------------------------
    
    module ClassMethods
    
      def url_for(api, method, id=nil, options={})
        url = "#{RHapi.options[:end_point]}/#{api}/#{RHapi.options[:version]}/#{method}"
        url << "/#{id}" unless id.nil?
        url << "?hapikey=#{RHapi.options[:api_key]}" if RHapi.options[:access_token].nil? or api.eql? 'leads'
        else
          url << "?access_token=#{RHapi.options[:access_token]}" # not all hubspot APIs support oAuth token calls 
        end
        
        raise(RHapi::UriError, "Options must be a hash in order to build the url.") unless options.is_a?(Hash)
        url << append_options(options) unless options.empty?
        url
      end 
      
      def append_options(options)
        query_string = ""
        options.each do |key, value|
          query_string << "&#{key.to_s}=#{value}"
        end
        query_string
      end
      
      def get(url)
        response = Curl::Easy.perform(url) do |curl|
          curl.on_failure do |response, err|
            RHapi::ConnectionError.raise_error("#{response.response_code}\n Error is: #{err.inspect}")
          end
        end
        RHapi::ConnectionError.raise_error( response.header_str) unless response.header_str =~ /2\d\d/
        RHapi::ConnectionError.raise_error(response.body_str) if response.body_str =~ /Error/i
        response
      end
      
    end # End class methods

    
  end
end
