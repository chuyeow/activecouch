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
      params.each do |k,v|
        k = k.intern if k.is_a?(String)
        self.send("#{k}=", v) if @attributes.has_key?(k)
      end
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

      def base_class
        class_of_active_couch_descendant(self)
      end

      # Returns the CouchDB database name that's backing this model. The database name is guessed from the name of the
      # class somewhat similar to ActiveRecord conventions.
      #
      # Examples:
      #   class Invoice < ActiveCouch::Base; end;
      #   file                  class               database_name
      #   invoice.rb            Invoice             invoices
      #
      #   class Invoice < ActiveCouch::Base; class Lineitem < ActiveCouch::Base; end; end;
      #   file                  class               database_name
      #   invoice.rb            Invoice::Lineitem   invoice_lineitems
      #
      #   module Invoice; class Lineitem < ActiveCouch::Base; end; end;
      #   file                  class               database_name
      #   invoice/lineitem.rb   Invoice::Lineitem   lineitems
      #
      # You can override this method or use <tt>set_database_name</tt> to override this class method to allow for names
      # that can't be inferred.
      def database_name
        base = base_class
        name = (unless self == base
          base.database_name
        else
          # Nested classes are prefixed with singular parent database name.
          if parent < ActiveCouch::Base
            contained = Inflector.singularize(parent.database_name)
            contained << '_'
          end
          "#{contained}#{Inflector.underscore(Inflector.demodulize(Inflector.pluralize(base.name)))}"
        end)
        set_database_name(name)
        name
      end

      # Sets the database name to the given value, or (if the value is nil or false) to the value returned by the
      # given block. Useful for setting database names that can't be automatically inferred from the class name.
      #
      # This method is aliased as <tt>database_name=</tt>.
      #
      # Example:
      #
      #   class Post < ActiveCouch::Base
      #     set_database_name 'legacy_posts'
      #   end
      def set_database_name(database = nil, &block)
        define_attr_method(:database_name, database, &block)
      end
      alias :database_name= :set_database_name

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

      def from_json(json)
        hash = JSON.parse(json)
        attributes = hash.reject{ |k,v| v.is_a?(Array) }
        associations = hash.reject{ |k,v| !v.is_a?(Array) }
        
        self.new(attributes)
      end

      # Defines an "attribute" method. A new (class) method will be created with the
      # given name. If a value is specified, the new method will
      # return that value (as a string). Otherwise, the given block
      # will be used to compute the value of the method.
      #
      # The original method, if it exists, will be aliased, with the
      # new name being
      # prefixed with "original_". This allows the new method to
      # access the original value.
      #
      # This method is stolen from ActiveRecord.
      #
      # Example:
      #
      #   class Foo < ActiveCouch::Base
      #     define_attr_method :database_name, 'foo'
      #     # OR
      #     define_attr_method(:database_name) do
      #       original_database_name + '_legacy'
      #     end
      #   end
      def define_attr_method(name, value = nil, &block)
        metaclass.send(:alias_method, "original_#{name}", name)
        if block_given?
          meta_def name, &block
        else
          metaclass.class_eval "def #{name}; #{value.to_s.inspect}; end"
        end
      end

      private
        # Returns the class descending directly from ActiveCouch in the inheritance hierarchy.
        def class_of_active_couch_descendant(klass)
          if klass.superclass == Base
            klass
          elsif klass.superclass.nil?
            raise ActiveCouchError, "#{name} doesn't belong in a hierarchy descending from ActiveCouch"
          else
            class_of_active_couch_descendant(klass.superclass)
          end
        end
    end # End class methods
  end # End class Base
end # End module ActiveCouch