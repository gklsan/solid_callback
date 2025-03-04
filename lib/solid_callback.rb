# frozen_string_literal: true

require "solid_callback/version"
require "solid_callback/core"
require "solid_callback/hooks"
require "solid_callback/method_wrapper"

module SolidCallback
  class Error < StandardError; end

  # This method is called when the module is included in a class
  def self.included(base)
    base.extend(SolidCallback::Core)
    base.extend(SolidCallback::Hooks)
    base.send(:include, SolidCallback::MethodWrapper)

    # Initialize callback store on the class
    base.instance_variable_set(:@_solid_callback_store, {
      before: {},
      after: {},
      around: {}
    })

    # Setup method_added hook to handle methods defined after including SolidCallback
    base.singleton_class.prepend(Module.new do
      def method_added(method_name)
        super
        # Delegate to SolidCallback's method added handler
        handle_method_added(method_name) if respond_to?(:handle_method_added)
      end
    end)
  end
end