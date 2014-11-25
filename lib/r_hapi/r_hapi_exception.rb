module RHapi
  class ConnectionError < StandardError
    attr :error_string

    def initialize(error_string)
      @error_string = error_string
    end

    def message
      @error_string
    end

    def self.raise_error(response, url=nil, payload='')
      exception = RHapi::ConnectionError.new("URL: #{url}\nPayload: #{payload.inspect}\nResponse: #{response}")
      raise(exception, exception.message)
    end

  end

  class UriError < TypeError; end

  class AttributeError < TypeError; end

end
