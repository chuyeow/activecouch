module ActiveCouch
  class Connection
    attr_accessor :server, :port
    
    def initialize(options = {})
      if !options.nil? && options.has_key?(:server)
        @server = options[:server]
        @port = options[:port] || '5984'
      else
        raise ConfigurationError, "Configuration hash must contain keys for server and port"
      end
    end
    
    def get
      nil
    end
    
    def put(data)
      
    end
  end
end