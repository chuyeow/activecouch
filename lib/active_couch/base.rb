module ActiveCouch
  class Base
    SPECIAL_MEMBERS =  %w(attributes associations connection callbacks)
    DEFAULT_ATTRIBUTES = %w(id rev)
    TYPES = { :text => "", :number => 0, :decimal => 0.0, :boolean => true }
    TYPES.default = ""
    
    # Initializes an ActiveCouch::Base object. The constructor accepts both a hash, as well as 
    # a block to initialize attributes
    #
    # Examples:
    #   class Person < ActiveCouch::Base
    #     has :name
    #   end
    #
    #   person1 = Person.new(:name => "McLovin")
    #   person1.name # => "McLovin"
    #
    #   person2 = Person.new do |p|
    #     p.name = "Seth"
    #   end
    #   person2.name # => "Seth"
    def initialize(params = {})
      # Object instance variable
      @attributes = {}; @associations = {}; @callbacks = Hash.new; @connection = self.class.connection
      # Initialize local variables from class instance variables
      klass_atts = self.class.attributes
      klass_assocs = self.class.associations
      klass_callbacks = self.class.callbacks
      # ActiveCouch::Connection object will be readable in every 
      # object instantiated from a subclass of ActiveCouch::Base
      SPECIAL_MEMBERS.each do |k|
        self.instance_eval "def #{k}; @#{k}; end"
      end
      # First, initialize all the attributes
      klass_atts.each_key do |property|
        @attributes[property] = klass_atts[property]
        self.instance_eval "def #{property}; attributes[:#{property}]; end"
        self.instance_eval "def #{property}=(val); attributes[:#{property}] = val; end"
        # These are special attributes which need aliases (for now, it's _id and _rev)
        if property.to_s[0,1] == '_'
          aliased_prop = property.to_s.slice(1, property.to_s.size)
          self.instance_eval "def #{aliased_prop}; self.#{property}; end"
          self.instance_eval "def #{aliased_prop}=(val); self.#{property}=(val); end"
        end
      end
      # Then, initialize all the associations
      klass_assocs.each_key do |k|
        @associations[k] = klass_assocs[k]
        self.instance_eval "def #{k}; @#{k} ||= []; end"
        # If you have has_many :people, this will add a method called add_person
        # to the object instantiated from the class
        self.instance_eval "def add_#{k.singularize}(val); @#{k} = #{k} << val; end"
      end
      # Finally, all the calbacks      
      klass_callbacks.each_key do |k|
        @callbacks[k] = klass_callbacks[k].dup
      end
      # Set any instance variables if any, which are present in the params hash
      from_hash(params)
      # Handle the block, which can also be used to initialize the object
      yield self if block_given?
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
      # First merge the attributes...
      hash.merge!(attributes.reject{ |k,v| v.nil? })
      # ...and then the associations
      associations.each_key { |name| hash.merge!({ name => self.__send__(name.to_s) }) }
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
    def save(options = {})
      database = options[:to_database] || self.class.database_name
      if id
        response = connection.put("/#{database}/#{id}", to_json)
      else
        response = connection.post("/#{database}", to_json)
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

    # Deletes a document from a CouchDB database. This is an instance-level delete method.
    # Example:
    #   class Person < ActiveCouch::Base
    #     has :name
    #   end
    #   
    #   person = Person.create(:name => 'McLovin')
    #   person.delete # true
    def delete(options = {})
      database = options[:from_database] || self.class.database_name
      
      if new?
        raise ArgumentError, "You must specify a revision for the document to be deleted"
      elsif id.nil?
        raise ArgumentError, "You must specify an ID for the document to be deleted"
      end
      response = connection.delete("/#{database}/#{id}?rev=#{rev}")
      # Set the id and rev to nil, since the object has been successfully deleted from CouchDB
      if response.code =~ /20[0,2]/
        self.id = nil; self.rev = nil
        true
      else
        false
      end
    end

    def marshal_dump # :nodoc:
      # Deflate using Zlib
      self.to_json
    end

    def marshal_load(str) # :nodoc:
      self.instance_eval do
        # Inflate first, and then parse the JSON
        hash = JSON.parse(str)
        initialize(hash)
      end
      self
    end        
    
    class << self # Class methods
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
            contained = parent.database_name.singularize
            contained << '_'
          end
          "#{contained}#{base.name.pluralize.demodulize.underscore}"
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
        # Set the attributes value to options[:with_default_value]
        # In the constructor, this will be used to initialize the value of 
        # the 'name' instance variable to the value in the hash
        @attributes[name] = options[:with_default_value] || TYPES[:which_is]
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
      
        @associations[name] = get_klass(name, options)
      end

      # Defines a single object which is a 'child' of this class. The has_one
      # function guesses the class of the child, based on the name of the association,
      # but can be over-ridden by the :class key in the options hash.
      # 
      # Examples:
      #
      #   class Child < ActiveCouch::Base
      #     has :name
      #   end
      #
      #   class GrandParent < ActiveCouch::Base
      #     has_one :child
      #   end
      def has_one(name, options = {})
        unless name.is_a?(String) || name.is_a?(Symbol)
          raise ArgumentError, "#{name} is neither a String nor a Symbol"
        end
      
        @associations[name] = get_klass(name, options)
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
      #   # This returns a single instance of an ActiveCouch::Base subclass
      #   people = Person.find(:first, :params => {:name => "McLovin"})
      #
      #   # This returns an array of ActiveCouch::Base subclass instances
      #   person = Person.find(:all, :params => {:name => "McLovin"})
      def find(*arguments)
        scope = arguments.slice!(0)
        search_params = arguments.slice!(0) || {}
        
        case scope
          when :all    then find_every(search_params)
          when :first  then find_every(search_params, {:limit => 1}).first
          else              find_one(scope)
        end
      end

      # Retrieves one or more object(s) from a CouchDB database, based on the search
      # parameters given. This method is similar to the find_by_sql method in
      # ActiveRecord, in a way that instead of using any conditions, we use a raw 
      # URL to query a CouchDB view.
      # 
      # Example:
      #   class Person < ActiveCouch::Base
      #     has :name
      #   end
      #
      #   # This returns a single instance of an ActiveCouch::Base subclass
      #   people = Person.find_from_url("/people/_view/by_name/by_name?key=%22Mclovin%22")
      def find_from_url(url)
        # If the url contains the word '_view' it means it will return objects as an array,
        # how ever if it doesn't it means the user is getting an ID-based url like /properties/abcd
        # which will only return a single object
        if url =~ /_view/
          instantiate_collection(connection.get(url))
        else
          begin
            instantiate_object(connection.get(url))
          rescue ResourceNotFound
            nil
          end
        end
      end

      # Retrieves the count of the number of objects in the CouchDB database, based on the
      # search parameters given.
      #
      # Example:
      #   class Person < ActiveCouch::Base
      #     has :name
      #   end
      #
      #   # This returns the count of the number of objects
      #   people_count = Person.count(:params => {:name => "McLovin"})
      def count(search_params = {})
        path = "/#{database_name}/_view/#{query_string(search_params[:params], {:limit => 0})}"
        result = connection.get(path)
        
        JSON.parse(result)['total_rows'].to_i
      end

      # Retrieves the count of the number of objects in the CouchDB database, irrespective of
      # any search criteria
      #
      # Example:
      #   class Person < ActiveCouch::Base
      #     has :name
      #   end
      #
      #   # This returns the count of the number of objects
      #   people_count = Person.count_all
      def count_all
        result = connection.get("/#{database_name}")
        JSON.parse(result)['doc_count'].to_i
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

      # Deletes a document from the CouchDB database, based on the id and rev parameters passed to it.
      # Returns true if the document has been deleted
      #
      # Example:
      #   class Person < ActiveCouch::Base
      #     has :name
      #   end
      # 
      #   Person.delete(:id => 'abc-def', :rev => '1235')
      def delete(options = {})
        if options.nil? || !options.has_key?(:id) || !options.has_key?(:rev)
          raise ArgumentError, "You must specify both an id and a rev for the document to be deleted"
        end
        response = connection.delete("/#{self.database_name}/#{options[:id]}?rev=#{options[:rev]}")
        # Returns true if the 
        !(response.code =~ /20[0,2]/).nil?
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

      def inherited(subklass)
        subklass.class_eval do
          include ActiveCouch::Callbacks
        end
        
        subklass.instance_eval do
          @attributes = { :_id => nil, :_rev => nil }
          @associations = {}
          @callbacks = Hash.new([])
          @connection = ActiveCouch::Base.instance_variable_get('@connection')
        end
        
        SPECIAL_MEMBERS.each do |k|
          subklass.instance_eval "def #{k}; @#{k}; end"
        end
      end

      def base_class
        class_of_active_couch_descendant(self)
      end

      private
        # Generate a class from a name
        def get_klass(name, options)
          klass = options[:class]
          !klass.nil? && klass.is_a?(Class) ? klass : name.to_s.classify.constantize
        end
      
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
        def find_every(search_params, overriding_options = {})
          case from = search_params[:from]
          when String
            path = "#{from}"
          else
            options = search_params.reject { |k,v| k == :params }
            options.merge!(overriding_options)
            
            path = "/#{database_name}/_view/#{query_string(search_params[:params], options)}"
          end
          instantiate_collection(connection.get(path))
        end
        
        def find_one(id)
          path = "/#{database_name}/#{id}"
          begin
            instantiate_object(connection.get(path))
          rescue ResourceNotFound
            nil
          end
        end
        
        # Generates a query string by using the ActiveCouch convention, which is to
        # have the view defined by pre-pending the attribute to be queried with 'by_'
        # So for example, if the params hash is :name => 'McLovin',
        # the view associated with it will be /by_name/by_name?key="McLovin"
        def query_string(search_params, options)
          unless search_params.is_a?(Hash) || search_params.keys.size != 1
            raise ArgumentError, "Wrong options for ActiveCouch::Base#find" and return
          end

          key = search_params.keys.first
            
          query_string = "by_#{key}/by_#{key}?key=#{search_params[key].to_s.url_encode}"
          query_string = "#{query_string}&skip=#{options[:offset]}" unless options[:offset].nil?
          query_string = "#{query_string}&count=#{options[:limit]}" unless options[:limit].nil?
            
          query_string
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
          hash['rows'].collect { |row| self.new(row['value'].merge('_id' => row['id'])) }
        end
        
        # Instantiates an ActiveCouch::Base object, based on the result obtained from
        # the GET URL
        def instantiate_object(result)
          hash = JSON.parse(result)
          self.new(hash)
        end
    end # End class methods
    
    private
      def from_hash(hash)
        hash.each do |property, value|
          property = property.to_sym rescue property
          # This means a has_many association
          if value.is_a?(Array) && !(child_klass = @associations[property]).nil?
            value.each do |child|
              child.is_a?(Hash) ? child_obj = child_klass.new(child) : child_obj = child
              self.send "add_#{property.to_s.singularize}", child_obj
            end
          # This means a has_one association            
          elsif value.is_a?(Hash) && !(child_klass = @associations[property]).nil?
            self.send "add_#{property.to_s.singualize}", child_klass.new(value)
          # This means this is a normal attribute            
          else
            self.send("#{property}=", value) if respond_to?("#{property}=")
          end
        end
      end
  end # End class Base
end # End module ActiveCouch