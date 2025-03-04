RSpec.describe SolidCallback::Hooks do
  let(:test_class) do
    Class.new do
      extend SolidCallback::Core
      extend SolidCallback::Hooks

      @_solid_callback_store = {
        before: {},
        after: {},
        around: {}
      }
    end
  end

  describe "#before_call" do
    it "registers a before callback" do
      expect(test_class).to receive(:register_callback).with(:before, :log_before, {})

      test_class.before_call(:log_before)
    end

    it "passes options to register_callback" do
      options = { only: [:create], if: :should_log? }

      expect(test_class).to receive(:register_callback).with(:before, :log_before, options)

      test_class.before_call(:log_before, options)
    end
  end

  describe "#after_call" do
    it "registers an after callback" do
      expect(test_class).to receive(:register_callback).with(:after, :log_after, {})

      test_class.after_call(:log_after)
    end

    it "passes options to register_callback" do
      options = { except: [:destroy], unless: :skip_logging? }

      expect(test_class).to receive(:register_callback).with(:after, :log_after, options)

      test_class.after_call(:log_after, options)
    end
  end

  describe "#around_call" do
    it "registers an around callback" do
      expect(test_class).to receive(:register_callback).with(:around, :log_around, {})

      test_class.around_call(:log_around)
    end

    it "passes options to register_callback" do
      options = { only: [:update, :create] }

      expect(test_class).to receive(:register_callback).with(:around, :log_around, options)

      test_class.around_call(:log_around, options)
    end
  end

  describe "#wrap_methods" do
    it "calls wrap_method_with_callbacks for each method" do
      expect(test_class).to receive(:wrap_method_with_callbacks).with(:method1)
      expect(test_class).to receive(:wrap_method_with_callbacks).with(:method2)
      expect(test_class).to receive(:method_defined?).with(:method1).and_return(true)
      expect(test_class).to receive(:method_defined?).with(:method2).and_return(true)

      test_class.wrap_methods(:method1, :method2)
    end

    it "skips undefined methods" do
      expect(test_class).to receive(:wrap_method_with_callbacks).with(:method1)
      expect(test_class).not_to receive(:wrap_method_with_callbacks).with(:undefined_method)
      expect(test_class).to receive(:method_defined?).with(:method1).and_return(true)
      expect(test_class).to receive(:method_defined?).with(:undefined_method).and_return(false)

      test_class.wrap_methods(:method1, :undefined_method)
    end
  end

  describe "#skip_callbacks_for" do
    it "adds methods to skip list" do
      test_class.skip_callbacks_for(:method1, :method2)

      expect(test_class.instance_variable_get(:@_solid_callback_skip_methods)).to eq([:method1, :method2])
    end

    it "appends to existing skip list" do
      test_class.instance_variable_set(:@_solid_callback_skip_methods, [:method1])

      test_class.skip_callbacks_for(:method2, :method3)

      expect(test_class.instance_variable_get(:@_solid_callback_skip_methods)).to eq([:method1, :method2, :method3])
    end
  end
end