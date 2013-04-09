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

    def post(url, payload)
      data = payload.to_json
      response = Curl::Easy.http_post(url, data) do |curl| 
        curl.headers["Content-Type"] = "application/json"
        curl.on_failure do |response, err|
          RHapi::ConnectionError.raise_error("#{response.response_code}\n Error is: #{err.inspect}")
        end
        curl.on_complete do |response|
          RHapi::ConnectionError.raise_error(response.header_str) unless easy.header_str =~ /2\d\d/
          response
        end
      end
    end

    def http_delete(url) # Namespace to avoid clash with methods which implement delete 
      response = Curl::Easy.http_delete(url) do |curl|
        curl.on_failure do |response, err|
          RHapi::ConnectionError.raise_error("#{response.response_code}\n Error is: #{err.inspect}")
        end
      end
      RHapi::ConnectionError.raise_error(response.header_str) unless response.header_str =~ /2\d\d/
    end

    # Class methods -----------------------------------------------------------------------------
    
    module ClassMethods
    
      def url_for(route={}, options={})
        if RHapi.options[:api_key].nil? and RHapi.options[:access_token].nil?
          raise(RHapi::ConfigError, "Cannot make call without either oAuth access token or API key.")
        end
        url = "#{RHapi.options[:end_point]}"
        # unpack route -- define order to support ruby < 1.9
        url << "/#{route[:api]}" unless route[:api].nil?
        if route[:version].nil?
          url << "/#{RHapi.options[:version]}" 
        else
          url << "/#{route[:version]}"
        end
        url << "/#{route[:resource]}" unless route[:resource].nil?
        url << "/#{route[:filter]}" unless route[:filter].nil?
        url << "/#{route[:identifier]}" unless route[:identifier].nil?
        url << "/#{route[:member]}" unless route[:member].nil?
        url << "/#{route[:context]}" unless route[:context].nil?
        url << "/#{route[:method]}" unless route[:method].nil?
        if RHapi.options[:access_token].nil? or route[:api].eql? 'leads'
          if RHapi.options[:api_key].nil?
            raise(RHapi::ConfigError, "Call to legacy api requires api key.") unless RHapi.options[:access_token].nil?
          end
          url << "?hapikey=#{RHapi.options[:api_key]}"
        else
          url << "?token=#{RHapi.options[:access_token]}" # not all hubspot APIs support oAuth token calls 
        end
        
        raise(RHapi::UriError, "Options must be a hash in order to build the url.") unless options.is_a?(Hash)
        url << append_options(options) unless options.empty?
        url
      end 
      
      def append_options(options)
        query_string = ""
        options.each do |key, value|
          next if value.nil?
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
