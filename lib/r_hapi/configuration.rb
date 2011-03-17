module RHapi
  module Configuration
    VALID_OPTIONS_KEYS = [:api_key, :end_point, :hub_spot_site]
    DEFAULT_API_KEY = nil
    DEFAULT_END_POINT = "https://hubapi.com"
    DEFAULT_HUB_SPOT_SITE = nil
    
    attr_accessor *VALID_OPTIONS_KEYS
    
    def configure
      yield self
    end
    
  # Create a hash of options and their values
   def options
     Hash[VALID_OPTIONS_KEYS.map {|key| [key, send(key)] }]
   end

   # Reset all configuration options to defaults
   def reset
     self.api_key              = DEFAULT_API_KEY
     self.end_point            = DEFAULT_END_POINT
     self.hub_spot_site        = DEFAULT_HUB_SPOT_SITE
     self
   end
       
  end
end