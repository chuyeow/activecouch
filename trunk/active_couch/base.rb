require 'yaml'

module ActiveCouch
  class Base
    class << self
      attr_accessor :connection
      
      def define_instance_variable(var_name, default_value)
        unless var_name.is_a?(Symbol) || var_name.is_a?(String)
          raise IllegalArgumentError, "#{sym.inspect} is neither a String nor a Symbol"
        end

        class_eval <<-eval
          def #{var_name}; @#{var_name} ||= "#{default_value}"; end
          def #{var_name}=(val); @#{var_name} = val; end
        eval
      end
      
      def has(*args)
        # has can contain a series of symbols each of which will correspond to a text node
        # in the ActiveCouch::Base object
        # For e.g. has_one :name, :age, :sex, :location will define the instance variables 
        # @name, @age, @sex, @location with the default value of an empty string
        default_value = ""
        
        if args.last.is_a?(Hash)
          options = args.pop
          default_value = options[:with_default_value] if options.has_key?(:with_default_value)
        end
        args.each { |sym| define_instance_variable(sym, default_value) }
      end
      
      def has_many(*args)
        # has_many can contain a series of symbols each of which will correspond to an array node
        # in the ActiveCouch::Base object
        # For e.g. has_many :airports will define the instance variable
        # @airports with the default value of an empty array
        args.each do |sym|
          unless sym.is_a?(Symbol) || sym.is_a?(String)
            raise IllegalArgumentError, "#{sym.inspect} is neither a String nor a Symbol"
          end

          class_eval <<-eval
            def #{sym}; @#{sym} ||= []; end
            def #{sym}=(val); @#{sym} = val; end
          eval
        end
      end
      
      def establish_connection(spec = nil)
        spec = 'config/couch.yml' if spec.nil? # Default to a file path if spec is nil
        
        if spec.is_a?(Hash)
          @connection = Connection.new(spec)
        elsif spec.is_a?(String)
          begin  
          @connection = Connection.new(YAML::load(File.open(spec)))
          rescue
            raise ConfigurationError, "Error parsing config file (either wrongly formatted or missing): #{spec}"
          end
        else
          raise IllegalArgumentError, "Arguments must either be a hash or string"
        end
        
        @connection
      end
    end # end Class Methods
  end # end Class Base
end # end Module ActiveCouch