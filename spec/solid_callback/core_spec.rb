RSpec.describe SolidCallback::Core do
  let(:test_class) do
    Class.new do
      extend SolidCallback::Core

      @_solid_callback_store = {
        before: {},
        after: {},
        around: {}
      }
    end
  end

  describe "#callbacks_for" do
    it "returns callbacks for the specified type" do
      test_class.instance_variable_set(:@_solid_callback_store, {
        before: { log_before: { method: :log_before } },
        after: {},
        around: {}
      })

      expect(test_class.callbacks_for(:before)).to eq({ log_before: { method: :log_before } })
    end

    it "initializes callback store if not already initialized" do
      test_class.instance_variable_set(:@_solid_callback_store, nil)

      expect(test_class.callbacks_for(:before)).to eq({})
      expect(test_class.instance_variable_get(:@_solid_callback_store)).to eq({
                                                                                before: {},
                                                                                after: {},
                                                                                around: {}
                                                                              })
    end
  end

  describe "#register_callback" do
    it "registers a callback with default options" do
      test_class.register_callback(:before, :log_before)

      expect(test_class.instance_variable_get(:@_solid_callback_store)[:before]).to include(
                                                                                      log_before: {
                                                                                        method: :log_before,
                                                                                        only: [:all],
                                                                                        except: [],
                                                                                        if: nil,
                                                                                        unless: nil
                                                                                      }
                                                                                    )
    end

    it "registers a callback with custom options" do
      test_class.register_callback(:after, :log_after, only: [:create, :update], if: :should_log?)

      expect(test_class.instance_variable_get(:@_solid_callback_store)[:after]).to include(
                                                                                     log_after: {
                                                                                       method: :log_after,
                                                                                       only: [:create, :update],
                                                                                       except: [],
                                                                                       if: :should_log?,
                                                                                       unless: nil
                                                                                     }
                                                                                   )
    end
  end

  describe "#callback_applicable?" do
    let(:instance) { double("TestInstance") }
    let(:callback) do
      {
        method: :log_callback,
        only: [:test_method],
        except: [:skip_method],
        if: :condition_method,
        unless: :unless_method
      }
    end

    context "with only/except constraints" do
      it "returns true when method is in only list" do
        callback[:only] = [:test_method]
        callback[:except] = []
        callback[:if] = nil
        callback[:unless] = nil

        expect(test_class.callback_applicable?(callback, :test_method, instance)).to be true
      end

      it "returns true when only is :all" do
        callback[:only] = [:all]
        callback[:except] = []
        callback[:if] = nil
        callback[:unless] = nil

        expect(test_class.callback_applicable?(callback, :any_method, instance)).to be true
      end

      it "returns false when method is not in only list" do
        callback[:only] = [:other_method]
        callback[:except] = []
        callback[:if] = nil
        callback[:unless] = nil

        expect(test_class.callback_applicable?(callback, :test_method, instance)).to be false
      end

      it "returns false when method is in except list" do
        callback[:only] = [:all]
        callback[:except] = [:test_method]
        callback[:if] = nil
        callback[:unless] = nil

        expect(test_class.callback_applicable?(callback, :test_method, instance)).to be false
      end
    end

    context "with conditional constraints" do
      before do
        callback[:only] = [:all]
        callback[:except] = []
      end

      it "returns true when if condition returns true" do
        callback[:if] = :condition_method
        callback[:unless] = nil

        allow(instance).to receive(:condition_method).and_return(true)

        expect(test_class.callback_applicable?(callback, :test_method, instance)).to be true
      end

      it "returns false when if condition returns false" do
        callback[:if] = :condition_method
        callback[:unless] = nil

        allow(instance).to receive(:condition_method).and_return(false)

        expect(test_class.callback_applicable?(callback, :test_method, instance)).to be false
      end

      it "returns true when unless condition returns false" do
        callback[:if] = nil
        callback[:unless] = :unless_method

        allow(instance).to receive(:unless_method).and_return(false)

        expect(test_class.callback_applicable?(callback, :test_method, instance)).to be true
      end

      it "returns false when unless condition returns true" do
        callback[:if] = nil
        callback[:unless] = :unless_method

        allow(instance).to receive(:unless_method).and_return(true)

        expect(test_class.callback_applicable?(callback, :test_method, instance)).to be false
      end

      it "handles proc conditions" do
        callback[:if] = -> { true }

        allow(instance).to receive(:instance_exec).and_return(true)

        expect(test_class.callback_applicable?(callback, :test_method, instance)).to be true
      end
    end
  end

  describe "#evaluate_condition" do
    let(:instance) { double("TestInstance") }

    it "calls method on instance when condition is a Symbol" do
      allow(instance).to receive(:condition_method).and_return(true)

      expect(test_class.evaluate_condition(:condition_method, instance)).to be true
    end

    it "calls method on instance when condition is a String" do
      allow(instance).to receive(:condition_method).and_return(true)

      expect(test_class.evaluate_condition("condition_method", instance)).to be true
    end

    it "executes proc in instance context when condition is a Proc" do
      condition = -> { self.some_value }

      allow(instance).to receive(:instance_exec).and_return(true)

      expect(test_class.evaluate_condition(condition, instance)).to be true
    end

    it "returns true for other condition types" do
      expect(test_class.evaluate_condition(nil, instance)).to be true
    end
  end

  describe "#wrap_method_with_callbacks" do
    let(:test_class_with_method) do
      Class.new do
        extend SolidCallback::Core
        include SolidCallback::MethodWrapper

        @_solid_callback_store = {
          before: {},
          after: {},
          around: {}
        }

        def test_method(value)
          "original: #{value}"
        end
      end
    end

    it "creates alias for original method" do
      test_class_with_method.wrap_method_with_callbacks(:test_method)

      instance = test_class_with_method.new
      expect(instance.respond_to?(:_solid_callback_original_test_method, true)).to be true
    end

    it "wraps method with callback handling" do
      # Add test callbacks
      test_class_with_method.instance_variable_set(:@_solid_callback_store, {
        before: { log_before: { method: :log_before, only: [:all], except: [] } },
        after: { log_after: { method: :log_after, only: [:all], except: [] } },
        around: {}
      })

      # Add callback methods
      test_class_with_method.class_eval do
        private

        def log_before
          @log ||= []
          @log << "before"
        end

        def log_after
          @log ||= []
          @log << "after"
        end

        def log
          @log
        end
      end

      # Wrap the method
      test_class_with_method.wrap_method_with_callbacks(:test_method)

      # Test execution
      instance = test_class_with_method.new
      result = instance.test_method(42)

      expect(result).to eq("original: 42")
      expect(instance.send(:log)).to eq(["before", "after"])
    end
  end
end