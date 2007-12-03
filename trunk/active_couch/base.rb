module ActiveCouch
  class ActiveCouchError < StandardError
  end
  
  class IllegalArgumentError < ActiveCouchError
  end
  
  class Base
    class << self
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
        # has_many can contain a series of symbols each of which will correspond to a text node
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
    end # end Class Methods
  end # end Class Base
end # end Module ActiveCouch