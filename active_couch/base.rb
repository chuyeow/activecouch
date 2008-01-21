module ActiveCouch
  class Base
    SPECIAL_MEMBERS =  %w(attributes associations connection)
    DEFAULT_ATTRIBUTES = %w(id rev)

    def initialize(params = {})
      # Object instance variable
      @attributes, @associations, @connection, klass_atts, klass_assocs = {}, {}, self.class.connection, self.class.attributes, self.class.associations
      # ActiveCouch::Connection object will be readable in every 
      # object instantiated from a subclass of ActiveCouch::Base
      SPECIAL_MEMBERS.each do |k|
        self.instance_eval "def #{k}; @#{k}; end"
      end
      
      klass_atts.each_key do |k|
        @attributes[k] = klass_atts[k].dup
        self.instance_eval "def #{k}; attributes[:#{k}].value; end"
        self.instance_eval "def #{k}=(val); attributes[:#{k}].value = val; end"
      end
      
      DEFAULT_ATTRIBUTES.each do |x|
        self.instance_eval "def #{x}; _#{x}; end"
        self.instance_eval "def #{x}=(val); self._#{x}=(val); end"
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

    # Generates a JSON representation of an instance of a subclass of ActiveCouch::Base.
    # Ignores attributes which have a nil value.
    # 
    # Examples:
    #   class Person < ActiveCouch::Base
    #     has :name, :which_is => :text, :with_default_value => "McLovin"
    #   end
    #   
    #   person = Person.new
    #   person.to_json # {"name":"McLovin"}
    #
    #   class AgedPerson < ActiveCouch::Base
    #     has :age, :which_is => :decimal, :with_default_value => 3.5
    #   end
    #
    #   aged_person = AgedPerson.new
    #   aged_person.id = 'abc-def'
    #   aged_person.to_json # {"age":3.5, "_id":"abc-def"}
    def to_json
      hash = {}
      
      attributes.each_value { |v| hash.merge!(v.to_hash) unless v.nil? }
      associations.each_value { |v| hash.merge!(v.to_hash) }
      # and by the Power of Grayskull, convert the hash to json
      hash.to_json
    end

    # Saves a document into a CouchDB database. A document can be saved in two ways.
    # One if it has been set an ID by the user, in which case the connection object 
    # needs to use an HTTP PUT request to the URL /database/user_generated_id.
    # For the document needs a CouchDB-generated ID, the connection object needs
    # to use an HTTP POST request to the URL /database.
    # 
    # Examples:
    #   class Person < ActiveCouch::Base
    #     has :name, :which_is => :text
    #   end
    #
    #   person = Person.new(:name => 'McLovin')
    #   person.id = 'abc'
    #   person.save # true
    #   person.new? # false
    def save
      if id
        response = connection.put("/#{self.class.database_name}/#{id}", to_json)
      else
        response = connection.post("/#{self.class.database_name}", to_json)
      end
      # Parse the JSON obtained from the body...
      results = JSON.parse(response.body)
      # ...and set the default id and rev attributes
      DEFAULT_ATTRIBUTES.each { |a| self.__send__("#{a}=", results[a]) }
      # Response sent will be 201, if the save was successful [201 corresponds to 'created']
      return response.code == '201'
    end

    # Checks to see if a document has been persisted in a CouchDB database.
    # If a document has been retrieved from CouchDB, or has been persisted in
    # a CouchDB database, the attribute _rev would not be nil.
    # 
    # Examples:
    #   class Person < ActiveCouch::Base
    #     has :name, :which_is => :text
    #   end
    #
    #   person = Person.new(:name => 'McLovin')
    #   person.id = 'abc'
    #   person.save # true
    #   person.new? # false
    def new?
      rev.nil?
    end

    # Deletes a document from a CouchDB database.
    def delete
      if new?
        raise ActiveCouchError, "You must specify a revision for the document to be deleted"
      elsif id.nil?
        raise ActiveCouchError, "You must specify an ID for the document to be deleted"
      else
        connection.delete("/#{self.class.database_name}/#{id}?rev=#{rev}")
      end
    end

    class << self # Class methods

      def inherited(subklass)
        # TODO: Need a cleaner way to do this
        subklass.instance_variable_set "@attributes", { :_id => Attribute.new(:_id, :with_default_value => nil), 
                                                        :_rev => Attribute.new(:_rev, :with_default_value => nil) }
        subklass.instance_variable_set "@associations", {}
        subklass.instance_variable_set "@connections", nil
                                                        
        SPECIAL_MEMBERS.each do |k|
          subklass.instance_eval "def #{k}; @#{k}; end"
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

      # Sets the site which the ActiveCouch object has to connect to, which
      # initializes an ActiveCouch::Connection object.
      #
      # Example:
      #   class Person < ActiveCouch::Base
      #     site 'localhost:5984'
      #   end
      #
      #   Person.connection.nil? # false
      def site(site)
        @connection = Connection.new(site)
      end

      # Defines an attribute for a subclass of ActiveCouch::Base. The parameters
      # for this method include name, which is the name of the attribute as well as
      # an options hash.
      # 
      # The options hash can contain the key 'which_is' which can
      # have possible values :text, :decimal, :number. It can also contain the key 
      # 'with_default_value' which can set a default value for each attribute defined
      # in the subclass of ActiveCouch::Base
      # 
      # Examples:
      #   class Person < ActiveCouch::Base
      #     has :name
      #   end
      #
      #   person = Person.new
      #   p.name.methods.include?(:name) # true
      #   p.name.methods.include?(:name=) # false
      #
      #   class AgedPerson < ActiveCouch::Base
      #     has :age, :which_is => :number, :with_default_value = 18
      #   end
      #
      #   person = AgedPerson.new
      #   person.age # 18
      def has(name, options = {})
        unless name.is_a?(String) || name.is_a?(Symbol)
          raise ArgumentError, "#{name} is neither a String nor a Symbol"
        end
        @attributes[name] = Attribute.new(name, options)  
      end

      # Defines an array of objects which are 'children' of this class. The has_many
      # function guesses the class of the child, based on the name of the association,
      # but can be over-ridden by the :class key in the options hash.
      # 
      # Examples:
      #
      #   class Person < ActiveCouch::Base
      #     has :name
      #   end
      #
      #   class GrandPerson < ActiveCouch::Base
      #     has_many :people # which will create an empty array which can contain 
      #                      # Person objects
      #   end
      def has_many(name, options = {})
        unless name.is_a?(String) || name.is_a?(Symbol)
          raise ArgumentError, "#{name} is neither a String nor a Symbol"
        end
        @associations[name] = HasManyAssociation.new(name, options)
      end

      # Initializes an object of a subclass of ActiveCouch::Base based on a JSON
      # representation of the object.
      # 
      # Example:
      #   class Person < ActiveCouch::Base
      #     has :name
      #   end
      #
      #   person = Person.from_json('{"name":"McLovin"}')
      #   person.name # "McLovin"
      def from_json(json)
        hash = JSON.parse(json)
        # Create new based on parsed 
        self.new(hash)
      end

      # Retrieves one or more object(s) from a CouchDB database, based on the search
      # parameters given.
      # 
      # Example:
      #   class Person < ActiveCouch::Base
      #     has :name
      #   end
      # 
      #   people = Person.find(:first, :params => {:name => "McLovin"})
      #   person = Person.find(:all, :params => {:name => "McLovin"})
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
      # 
      # Example:
      #   class Person < ActiveCouch::Base
      #     has :name
      #   end
      #
      #   person = Person.create(:name => "McLovin")
      #   person.id.nil? # false
      #   person.new?    # false
      def create(arguments)
        unless arguments.is_a?(Hash)
          raise ArgumentError, "The arguments must be a Hash"
        else
          new_record = self.new(arguments)
          new_record.save
          new_record
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
        
        # Instantiates a collection of ActiveCouch::Base objects, based on the 
        # result obtained from a CouchDB View.
        #
        # As per the CouchDB Permanent View API, the result set will be contained 
        # within a JSON hash as an array, with the key 'rows'
        # The actual CouchDB object which needs to be initialized is obtained with 
        # the key 'value'
        def instantiate_collection(result)
          hash = JSON.parse(result)
          hash['rows'].collect { |row| self.new(row['value']) }
        end
    end # End class methods
    
    private
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
  end # End class Base
end # End module ActiveCouch