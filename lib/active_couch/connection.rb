# Connection class borrowed from ActiveResource
require 'net/https'
require 'date'
require 'time'
require 'uri'
require 'benchmark'

module ActiveCouch
  class ConnectionError < StandardError # :nodoc:
    attr_reader :response

    def initialize(response, message = nil)
      @response = response
      @message  = message
    end

    def to_s
      "Failed with #{response.code} #{response.message if response.respond_to?(:message)}"
    end
  end

  # 3xx Redirection
  class Redirection < ConnectionError # :nodoc:
    def to_s; response['Location'] ? "#{super} => #{response['Location']}" : super; end    
  end 

  # 4xx Client Error
  class ClientError < ConnectionError; end # :nodoc:
  
  # 404 Not Found
  class ResourceNotFound < ClientError; end # :nodoc:
  
  # 409 Conflict
  class ResourceConflict < ClientError; end # :nodoc:

  # 412 Precondition Failed - this is returned when there is an update conflict (usually means revisions don't match).
  class UpdateConflict < ClientError # :nodoc:
    def to_s
      "Failed with #{response.code} #{response.message if response.respond_to?(:message)}. Body: #{response.body}"
    end
  end

  # 5xx Server Error
  class ServerError < ConnectionError; end # :nodoc:

  # 405 Method Not Allowed
  class MethodNotAllowed < ClientError # :nodoc:
    def allowed_methods
      @response['Allow'].split(',').map { |verb| verb.strip.downcase.to_sym }
    end
  end

  # Class to handle connections to remote web services.
  # This class is used by ActiveCouch::Base to interface with REST
  # services.
  class Connection
    attr_reader :site

    class << self
      def requests
        @@requests ||= []
      end
    end

    # The +site+ parameter is required and will set the +site+
    # attribute to the URI for the remote resource service.
    def initialize(site)
      raise ArgumentError, 'Missing site URI' unless site
      init_site_with_path(site)
    end

    # Set URI for remote service.
    def site=(site)
      @site = site.is_a?(URI) ? site : URI.parse(site)
    end

    # Execute a GET request.
    # Used to get (find) resources.
    def get(path, headers = {})
      request(:get, path, build_request_headers(headers)).body
    end

    # Execute a DELETE request (see HTTP protocol documentation if unfamiliar).
    # Used to delete resources.
    def delete(path, headers = {})
      request(:delete, path, build_request_headers(headers))
    end

    # Execute a PUT request (see HTTP protocol documentation if unfamiliar).
    # Used to update resources.
    def put(path, body = '', headers = {})
      request(:put, path, body.to_s, build_request_headers(headers))
    end

    # Execute a POST request.
    # Used to create new resources.
    def post(path, body = '', headers = {})
      request(:post, path, body.to_s, build_request_headers(headers))
    end


    private
      # Makes request to remote service.
      def request(method, path, *arguments)
        result = nil
        time = Benchmark.realtime { result = http.send(method, path, *arguments) }
        handle_response(result)
      end

      # Handles response and error codes from remote service.
      def handle_response(response)
        case response.code.to_i
          when 301,302
            raise(Redirection.new(response))
          when 200...400
            response
          when 404
            raise(ResourceNotFound.new(response))
          when 405
            raise(MethodNotAllowed.new(response))
          when 409
            raise(ResourceConflict.new(response))
          when 412
            raise(UpdateConflict.new(response))
          when 422
            raise(ResourceInvalid.new(response))
          when 401...500
            raise(ClientError.new(response))
          when 500...600
            raise(ServerError.new(response))
          else
            raise(ConnectionError.new(response, "Unknown response code: #{response.code}"))
        end
      end

      # Creates new Net::HTTP instance for communication with
      # remote service and resources.
      def http
        http             = Net::HTTP.new(@site.host, @site.port)
        http.use_ssl     = @site.is_a?(URI::HTTPS)
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE if http.use_ssl
        http
      end

      def default_header
        @default_header ||= { 'Content-Type' => 'application/json' }
      end
      
      # Builds headers for request to remote service.
      def build_request_headers(headers)
        authorization_header.update(default_header).update(headers)
      end
      
      # Sets authorization header; authentication information is pulled from credentials provided with site URI.
      def authorization_header
        (@site.user || @site.password ? { 'Authorization' => 'Basic ' + ["#{@site.user}:#{ @site.password}"].pack('m').delete("\r\n") } : {})
      end
      
      def init_site_with_path(site)
        site = "#{site}:5984" if site.is_a?(String) && (site =~ /http\:\/\/(.*?)\:(\d+)/).nil?
        @site = URI.parse(site)
      end
  end
end
