module ActiveCouch
  class Base
    SPECIAL_MEMBERS = %w(attributes associations connection)

    def initialize(params = {})
      # Object instance variable
      @attributes, @associations, @connection, klass_atts, klass_assocs = {}, {}, self.class.connection, self.class.attributes, self.class.associations
      # ActiveCouch::Connection object will be readable in every 
      # object instantiated from a subclass of ActiveCouch::Base
      SPECIAL_MEMBERS.each do |m|
        self.instance_eval "def #{m}; @#{m}; end"
      end
      
      klass_atts.each_key do |k|
        @attributes[k] = klass_atts[k].dup
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
      from_hash(params)
    end

    # Returns the "_id" of the CouchDB document represented by this instance.
    def id
      @id ||= attributes[:_id]
    end

    # Sets the "_id" of the CouchDB document represented by this instance.
    # This doesn't do anything unless this is a new document.
    def id=(new_id)
      if new?
        attributes[:_id] = @id = new_id
      else
        nil
      end
    end

    # Returns the "_rev" of the CouchDB document represented by this instance.
    def rev
      @rev ||= attributes[:_rev]
    end

    # Returns true if this is a new CouchDB document.
    def new?
      @rev.nil?
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

    def from_hash(hash)
      # TODO: 
      #  - Clean this up. Doesn't look very nice
      #  - Raise errors if attribute/association is not present
      hash.each do |k,v|
        k = k.to_sym rescue k
        if v.is_a?(Array) # This means this is a has_many association
          unless (assoc = @associations[k]).nil?
            name, child_klass = assoc.name, assoc.klass
            v.each do |child|
              child.is_a?(Hash) ? child_obj = child_klass.new(child) : child_obj = child
              self.send "add_#{Inflector.singularize(name)}", child_obj
            end
          end
        elsif v.is_a?(Hash) # This means this is a has_one association (which we might add later)
          # Do nothing for now. More later
        else # This means this is a normal attribute
          self.send("#{k}=", v) if @attributes.has_key?(k)
        end
      end
    end

    def save
      # POST to database with a JSON representation of the object
      response = connection.post("/#{self.class.database_name}", self.to_json)
      # Response sent will be 201, if the save was successful [201 corresponds to 'created']
      return response.code == '201'
    end

    class << self # Class methods

      # All classes inheriting from ActiveCouch::Base will have
      # class instance variables in SPECIAL_MEMBERS.
      def inherited(subklass)
        SPECIAL_MEMBERS.each do |x|
          subklass.instance_variable_set "@#{x}", {}
          subklass.instance_eval "def #{x}; @#{x}; end"
        end
      end

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

      def site(site)
        @connection = Connection.new(site)
      end

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

      def from_json(json)
        hash = JSON.parse(json)
        # Create new based on parsed 
        self.new(hash)
      end

      # Similar to ActiveResource convention, find operates with two different 
      # retrieval approaches:
      # * Find :first
      # * Find :all
      # This method is stolen from ActiveResource::Base
      def find(*arguments)
        scope = arguments.slice!(0)
        options = arguments.slice!(0) || {}
        
        case scope
          when :all    then find_every(options)
          when :first  then find_every(options).first
          else              raise ArgumentError("find must have the first parameter as either :all or :first")
        end
      end

      # Initializes a new subclass of ActiveCouch::Base and saves in the CouchDB database
      # as a new document
      def create(arguments)
        unless arguments.is_a?(Hash)
          raise ArgumentError, "The arguments must be a Hash"
        else
          new_record = self.new(arguments)
          new_record.save
          
          return new_record
        end
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
        
        # Returns an array of ActiveCouch::Base objects by querying a CouchDB permanent view
        def find_every(options)
          case from = options[:from]
          when String
            path = "#{from}"
          else
            path = "/#{database_name}/_view/#{query_string(options[:params])}"
          end
          instantiate_collection(connection.get(path))
        end
        
        # Generates a query string by using the ActiveCouch convention, which is to
        # have the view defined by pre-pending the attribute to be queried with 'by_'
        # So for example, if the params hash is :name => 'McLovin',
        # the view associated with it will be /by_name/by_name?key="McLovin"
        def query_string(params)
          if params.is_a?(Hash)
            params.each { |k,v| return "by_#{k}/by_#{k}?key=#{v.url_encode}" }
          else
            raise ArgumentError, "The value for the key 'params' must be a Hash"
          end
        end
        
        def instantiate_collection(result)
          # First parse the JSON
          hash = JSON.parse(result)
          # As per the CouchDB Permanent View API, the result set will be contained 
          # within a JSON hash as an array, with the key 'rows'
          # The actual CouchDB object which needs to be initialized is obtained with 
          # the key 'value'
          hash['rows'].collect { |row| self.new(row['value']) }
        end
    end # End class methods
  end # End class Base
end # End module ActiveCouch