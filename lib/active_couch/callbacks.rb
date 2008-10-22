module ActiveCouch
  module Callbacks
    CALLBACKS = %w(before_save after_save before_delete after_delete)
    
    def self.included(base)
      # Alias methods which will have callbacks, (for now only save and delete).
      # This creates 2 pairs of methods: save_with_callbacks, save_without_callbacks,
      # delete_with_callbacks, delete_without_callbacks
      #
      # save_without_callbacks and delete_without_callbacks
      # have the same behaviour as the save and delete methods, respectively
      [:save, :delete].each do |method|
        base.send :alias_method_chain, method, :callbacks
      end
      
      CALLBACKS.each do |method|
        base.class_eval <<-"end_eval"
          def self.#{method}(*callbacks, &block)
            callbacks << block if block_given?
            # Assumes that the default value for the callbacks hash in the
            # including class is an empty array
            self.callbacks[#{method.to_sym.inspect}] = self.callbacks[#{method.to_sym.inspect}] + callbacks
          end
        end_eval
      end
    end # end method self.included 
    
    def before_save() end
    
    def after_save() end
      
    def before_delete() end
      
    def after_delete() end
    
    def save_with_callbacks(opts = {})
      return false if callback(:before_save) == false
      result = save_without_callbacks(opts)
      callback(:after_save)
      result
    end
    private :save_with_callbacks
    
    def delete_with_callbacks(opts = {})
      return false if callback(:before_delete) == false
      result = delete_without_callbacks(opts)
      callback(:after_delete)
      result
    end
    private :delete_with_callbacks
    
    def find_with_callbacks
      return false if callback(:before_find) == false
      result = find_without_callbacks
      callback(:after_find)
      result
    end
    private :find_with_callbacks
    
    private
      def callback(method)
        callbacks_for(method).each do |callback|
          result = case callback
            when Symbol
              self.send(callback)
            when String
              eval(callback, binding)
            when Proc, Method
              callback.call(self)
            else
              if callback.respond_to?(method)
                callback.send(method, self)
              else
                raise ActiveCouchError, "Callbacks must be a symbol denoting the method to call, a string to be evaluated, a block to be invoked, or an object responding to the callback method."
              end
          end
          return false if result == false
        end

        result = send(method) if respond_to?(method)

        return result
      end
      
      def callbacks_for(method)
        self.class.callbacks[method.to_sym]
      end
  end # end module Callbacks
end # end module ActiveCouch