module RHapi
  class ConnectionError < StandardError
    attr_accessor :response, :url, :payload

    def initialize(_response, _url, _payload)
      @response = _response
      @url = _url
      @payload = _payload
    end

    def message
      res = self.url+'\n'
      res += self.payload+'\n'
      res += self.response.header_str+'\n'
      res += self.response.body_str
      res
    end

    def http_status_code
      # Matches the last HTTP Status - following the HTTP protocol specification 'Status-Line = HTTP-Version SP Status-Code SP Reason-Phrase CRLF'
      statuses = response.header_str.scan(/HTTP\/\d\.\d\s(\d+\s.+)\r\n/).map{ |match|  match[0] }
      statuses.last.strip
    end

    def self.raise_error(response, url=nil, payload='')
      exception = RHapi::ConnectionError.new(response, url, payload)
      raise(exception, exception.message)
    end

  end

  class UriError < TypeError; end

  class AttributeError < TypeError; end

end
