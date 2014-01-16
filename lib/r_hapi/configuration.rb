module RHapi
  module Configuration
    VALID_OPTIONS_KEYS = [:api_key, :access_token, :end_point, :hub_spot_site, :version, :api_timeout]
    DEFAULT_API_KEY       = nil
    DEFAULT_ACCESS_TOKEN  = nil
    DEFAULT_END_POINT     = "https://api.hubapi.com"
    DEFAULT_VERSION       = "v1"
    DEFAULT_HUB_SPOT_SITE = nil
    DEFAULT_API_TIMEOUT   = 0.4
    
    attr_accessor *VALID_OPTIONS_KEYS
    
    def configure
      self.reset
      yield self
    end
    
    # Create a hash of options and their values
   def options
     Hash[VALID_OPTIONS_KEYS.map {|key| [key, send(key)] }]
   end

   # Reset all configuration options to defaults
   def reset
     self.api_key              = DEFAULT_API_KEY
     self.access_token         = DEFAULT_ACCESS_TOKEN
     self.end_point            = DEFAULT_END_POINT
     self.hub_spot_site        = DEFAULT_HUB_SPOT_SITE
     self.version              = DEFAULT_VERSION
     self.api_timeout          = DEFAULT_API_TIMEOUT
     self
   end
       
  end
end
