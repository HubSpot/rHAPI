module RHapi
  class ConnectionError < StandardError
    attr :error_string
    
    def initialize(error_string)
      @error_string = error_string
    end
    
    def message
      if @error_string =~ /401/
        "HubSopt returned a 401 error:  #{error_string}" 
      elsif @error_string =~ /404/
        "HubSopt returned a 404 error:  #{error_string}"
      elsif @error_string =~ /500/
        "HubSopt returned a 500 error:  #{error_string}"
      else
        @error_string
      end
    end
    
    def self.raise_error(response)
      exception = RHapi::ConnectionError.new(response)
      raise(exception, exception.message)
    end 
    
  end
  
  class UriError < TypeError
  end
  
end