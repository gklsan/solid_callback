module SolidCallback
  module Core
    # Get all callbacks of a specific type
    def callbacks_for(type)
      @_solid_callback_store ||= { before: {}, after: {}, around: {} }
      @_solid_callback_store[type]
    end

    # Register a callback
    def register_callback(type, callback_method, options = {})
      # Make sure callback store exists
      @_solid_callback_store ||= { before: {}, after: {}, around: {} }

      # Normalize options
      only = Array(options[:only] || :all)
      except = Array(options[:except] || [])
      if_condition = options[:if]
      unless_condition = options[:unless]

      # Store the callback information
      @_solid_callback_store[type][callback_method] = {
        method: callback_method,
        only: only,
        except: except,
        if: if_condition,
        unless: unless_condition
      }
    end

    # Check if a callback should be run for a method
    def callback_applicable?(callback, method_name, instance)
      # Check only/except constraints
      return false if callback[:except].include?(method_name)
      return false unless callback[:only] == [:all] || callback[:only].include?(method_name)

      # Check conditional constraints
      if callback[:if]
        condition = callback[:if]
        return false unless evaluate_condition(condition, instance)
      end

      if callback[:unless]
        condition = callback[:unless]
        return false if evaluate_condition(condition, instance)
      end

      true
    end

    # Evaluate a condition (symbol method name, proc, or lambda)
    def evaluate_condition(condition, instance)
      case condition
      when Symbol, String
        instance.send(condition)
      when Proc
        instance.instance_exec(&condition)
      else
        true
      end
    end

    # Handle method_added hook
    def handle_method_added(method_name)
      # Skip if we're in the process of defining a wrapped method
      return if @_solid_callback_wrapping_method

      # Skip special methods and private/protected methods
      return if method_name.to_s.start_with?('_solid_callback_')
      return if private_method_defined?(method_name) || protected_method_defined?(method_name)

      wrap_method_with_callbacks(method_name)
    end

    # Wrap a method with callbacks
    def wrap_method_with_callbacks(method_name)
      return unless instance_methods(false).include?(method_name)

      @_solid_callback_wrapping_method = true

      # Create a reference to the original method
      alias_method "_solid_callback_original_#{method_name}", method_name

      # Redefine the method with callbacks
      define_method(method_name) do |*args, &block|
        run_callbacks(:before, method_name)

        # Execute around callbacks or the original method
        result = run_around_callbacks(method_name, args, block)

        run_callbacks(:after, method_name)

        result
      end

      @_solid_callback_wrapping_method = false
    end
  end
end