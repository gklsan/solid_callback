module SolidCallback
  module Hooks
    # Before hooks
    def before_call(method_name, options = {})
      register_callback(:before, method_name, options)
    end

    # After hooks
    def after_call(method_name, options = {})
      register_callback(:after, method_name, options)
    end

    # Around hooks
    def around_call(method_name, options = {})
      register_callback(:around, method_name, options)
    end

    # Register all methods that need callbacks
    def wrap_methods(*method_names)
      method_names.each do |method_name|
        wrap_method_with_callbacks(method_name) if method_defined?(method_name)
      end
    end

    # Skip callbacks for specific methods
    def skip_callbacks_for(*method_names)
      @_solid_callback_skip_methods ||= []
      @_solid_callback_skip_methods.concat(method_names)
    end
  end
end