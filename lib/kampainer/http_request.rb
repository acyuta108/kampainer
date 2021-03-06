require 'benchmark'
require 'net/http'

module Kampainer

  # Generic Net::HTTP wrapper that logs the request and response.
  class HttpRequest
    attr_reader :uri, :request
    attr_reader :headers
    attr_reader :logger

    def initialize(method, path, headers, logger)
      @headers = headers
      @logger = logger
      @uri = URI(path)
      @request = Net::HTTP.const_get(method.capitalize).new(uri)
    end

    # Create HTTP request with provided headers.
    # Invoke request over HTTPS.
    # Return response on success or log failure and throw error.
    def send(action_name, data)
      headers.each { |k, v| request[k] = v }
      request.body = data
      response = log_request_response(data) do
        https(uri).request(request)
      end
      fail_unless_expected_response response, Net::HTTPSuccess
      response.body
    end

    def https(uri)
      Net::HTTP.new(uri.host, uri.port).tap do |http|
        http.use_ssl = true
      end
    end

    # Log URI, method, data
    # Start timer.
    # Yield URI, method, data.
    # Log response and time taken.
    def log_request_response(data = nil)
      logger.info "[#{self.class.name}] request = #{request.method} #{uri}"
      logger.info "[#{self.class.name}] headers = #{headers.inspect}"
      logger.info "[#{self.class.name}] data = #{data}"
      response = nil
      tms = Benchmark.measure do
        response = yield
      end
      logger.info("[#{self.class.name}] response (#{ms(tms)}ms): #{response.inspect} #{response.body}")
      response
    end

    def ms(tms)
      (tms.real*1000).round(3)
    end

    class UnexpectedHttpResponse < StandardError
      attr_reader :response

      def initialize(response)
        @response = response
        super "#{response.message} (#{response.code}): #{response.body}"
      end
    end

    def fail_unless_expected_response(response, *allowed_responses)
      unless allowed_responses.any? { |allowed| response.is_a?(allowed) }
        logger.error "#{response.inspect}: #{response.body}"
        raise UnexpectedHttpResponse, response
      end
      response
    end
  end
end
