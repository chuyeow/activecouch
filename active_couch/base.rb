module ActiveCouch
  class Base
    def initialize(params = {})
      # Object instance variable
      @attributes, @associations, klass_atts, klass_assocs = {}, {}, self.class.attributes, self.class.associations
      
      %w(attributes associations).each do |m|
        self.instance_eval "def #{m}; @#{m}; end"
      end
      
      klass_atts.each_key do |k|
        @attributes[k] = klass_atts[k].clone
        self.instance_eval "def #{k}; attributes[:#{k}].value; end"
        self.instance_eval "def #{k}=(val); attributes[:#{k}].value = val; end"
      end
      
      klass_assocs.each_key do |k|
        @associations[k] = HasManyAssociation.new(klass_assocs[k].name, :class => klass_assocs[k].klass)
        self.instance_eval "def #{k}; associations[:#{k}].container; end"
        # If you have has_many :people, this will add a method called add_person to the object instantiated
        # from the class
        self.instance_eval "def add_#{Inflector.singularize(k)}(val); associations[:#{k}].push(val); end"
      end
      # Set any instance variables if any, which are present in the params hash
      params.each {|k,v| self.send("#{k}=", v) if @attributes.has_key?(k)}
    end

    def to_json
      hash = {}
      # @attributes and @associations are hashes. Get all
      # attributes/associations and merge them into a single hash 
      attributes.each_value { |v| hash.merge!(v.to_hash) }
      associations.each_value { |v| hash.merge!(v.to_hash) }
      # and by the Power of Grayskull, convert the hash to json
      hash.to_json
    end

    class << self # Class methods
      def has(name, options = {})
        unless name.is_a?(String) || name.is_a?(Symbol)
          raise ArgumentError, "#{name} is neither a String nor a Symbol"
        end
        @attributes[name] = Attribute.new(name, options)  
      end

      def has_many(name, options = {})
        unless name.is_a?(String) || name.is_a?(Symbol)
          raise ArgumentError, "#{name} is neither a String nor a Symbol"
        end
        @associations[name] = HasManyAssociation.new(name, options)
      end
      
      # All classes inheriting from ActiveCouch::Base will have
      # a class instance variable called @attributes
      def inherited(subklass)
        %w(attributes associations).each do |x|
          subklass.instance_variable_set "@#{x}", {}
          subklass.instance_eval "def #{x}; @#{x}; end"
        end
      end
      # TODO: from_json to be used in conjunction with the constructor for ActiveCouch::Base
      # Constructor for ActiveCouch::Base must accept a hash of params
      def from_json
        
      end
    end # End class methods
  end # End class Base
end # End module ActiveCouch