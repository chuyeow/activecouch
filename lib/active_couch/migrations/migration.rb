require 'json'

module ActiveCouch
  class Migration
    class << self # Class Methods
      # Class instance variables
      @view = nil; @database = nil
      # These are accessible only at class-scope
      attr_accessor :view, :database
      # Set the view name and database name in the define method and then execute
      # the block
      def define(*args)
        # Borrowed from ActiveRecord::Base.find
        first = args.slice!(0); second = args.slice!(0)
        # Based on the classes of the arguments passed, set instance variables
        case first.class.to_s
          when 'String', 'Symbol' then view = first.to_s;  options = second || {}
          when 'Hash' then  view = ''; options = first
          else raise ArgumentError, "Wrong arguments used to define the view"
        end
        # Define the view and database instance variables based on the args passed
        # Don't care if the key doesn't exist
        @view, @database = get_view(view), options[:for_db]
        # Define alpha if specified as part of options
        @is_alpha = options[:is_alpha] || false
        # Block being called to set other parameters for the Migration
        yield if block_given?
      end
      
      def with_key(key = "")
        @key = key unless key.nil?
      end
      
      def with_filter(filter = "")
        @filter = filter unless filter.nil?
      end
      
      def include_attributes(*attrs)
        @attrs = attrs unless attrs.nil? || !attrs.is_a?(Array)
      end
      
      def view_js
        results_hash = { "_id" => "_design/#{@view}", "language" => view_language }
        results_hash["views"] =  view_function
        # Returns the JSON format for the function
        results_hash.to_json
      end

private
      def view_language
        @is_alpha ? 'text/javascript' : 'javascript'
      end

      def include_attrs
        attrs = "doc"
        unless @attrs.nil?
          js = @attrs.inject([]) {|result, att| result << "#{att}: doc.#{att}"}
          attrs = "{#{js.join(' , ')}}" if js.size > 0
        end
        attrs
      end
      
      def get_view(view)
        view_name = view
        view_name = "#{self}".underscore if view.nil? || view.length == 0
        view_name  
      end

      def view_function
        filter_present = !@filter.nil? && @filter.length > 0

        js = "function(doc) { "
        js << "if(#{@filter}) { " if filter_present
        js << "#{couchdb_view_mapper}(doc.#{@key}, #{include_attrs});"
        js << " } " if filter_present
        js << " }"
        
        # Return different structures based on whether 
        @is_alpha ? { @view => js } : { @view => {'map' => js} }
      end

      def couchdb_view_mapper
        @is_alpha ? 'map' : 'emit'
      end
    end # End Class Methods
  end # End Class Migration
end # End module ActiveCouch