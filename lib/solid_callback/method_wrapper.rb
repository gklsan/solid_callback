module SolidCallback
  module MethodWrapper
    private

    # Run callbacks of a specific type for a method
    def run_callbacks(type, method_name)
      callbacks = self.class.callbacks_for(type)
      return if callbacks.nil? || callbacks.empty?

      callbacks.each do |callback_method, callback_config|
        next unless self.class.callback_applicable?(callback_config, method_name, self)
        send(callback_method)
      end
    end

    # Run around callbacks as a chain
    def run_around_callbacks(method_name, args, block)
      around_callbacks = collect_applicable_around_callbacks(method_name)

      if around_callbacks.empty?
        # No around callbacks, directly call the original method
        send("_solid_callback_original_#{method_name}", *args, &block)
      else
        # Execute the chain of around callbacks
        execute_around_chain(around_callbacks, 0, method_name, args, block)
      end
    end

    # Collect all applicable around callbacks for a method
    def collect_applicable_around_callbacks(method_name)
      callbacks = self.class.callbacks_for(:around)
      return [] if callbacks.nil? || callbacks.empty?

      callbacks.select do |_, callback_config|
        self.class.callback_applicable?(callback_config, method_name, self)
      end.map { |callback_method, _| callback_method }
    end

    # Execute the chain of around callbacks
    def execute_around_chain(callbacks, index, method_name, args, block)
      if index >= callbacks.length
        # End of the chain, call the original method
        send("_solid_callback_original_#{method_name}", *args, &block)
      else
        # Call the next callback in the chain
        callback_method = callbacks[index]

        # Call the around callback with a continuation to the next callback
        send(callback_method) do
          execute_around_chain(callbacks, index + 1, method_name, args, block)
        end
      end
    end
  end
end