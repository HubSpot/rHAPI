module RHapi
  class RHapiException < RuntimeError
    attr :error_string
    
    def initialize(error_string)
      @error_string = error_string
    end
    
    def message
      if @error_string =~ /401/
        "HubSopt returned a 401 error. Make sure your API key is correct." 
      elsif @error_string =~ /404/
        "HubSopt returned a 404 error. Check the end point or the guid to make sure it is valid."
      elsif @error_string =~ /500/
        "HubSopt returned a 500 error."
      else
        # else send back the whole message.
        @error_string
      end
    end
    
    def self.raise_error(error_response)
      exception = RHapi::RHapiException.new(error_response)
      raise(exception, exception.message)
    end
    
  end
end