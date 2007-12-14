module ActiveCouch
  class Migration
    
    class << self # Class Methods
      
      # Set the view name and database name in the define method and then execute
      # the block
      def define(*args)
        # Borrowed from ActiveRecord::Base.find
        first = args.slice!(0); second = args.slice!(0)
        
        case first.class.to_s
          when 'String', 'Symbol' then view = first.to_s;  options = second || {}
          when 'Hash' then  view = ''; options = first
          else raise ArgumentError, "Wrong arguments used to define the view"
        end
        # Define the view and database instance variables based on the 
        @view = get_view(view)
        @database = options[:for_db] if options.has_key?(:for_db)
        # Block being called to set other parameters for the Migration
        yield
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
      
      def migrate
        filter_present = !@filter.nil? && @filter.length > 0

        js = "function(doc) {\n"
        js << "\tif(#{@filter}) {\n\t" if filter_present
        js << "\tmap(doc.#{@key}, #{include_attrs});\n"
        js << "\t}\n" if filter_present
        js << "}"
        
        js
      end

private
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
        view_name = Inflector.underscore("#{self}") if view.nil? || view.length == 0
        view_name  
      end

    end # End Class Methods
  end # End Class Migration
end # End module ActiveCouch