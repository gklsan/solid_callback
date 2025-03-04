# frozen_string_literal: true

RSpec.describe SolidCallback do
  it "has a version number" do
    expect(SolidCallback::VERSION).not_to be nil
  end

  describe ".included" do
    let(:test_class) do
      Class.new do
        include SolidCallback
      end
    end

    it "extends the class with Core module" do
      expect(test_class.singleton_class.included_modules).to include(SolidCallback::Core)
    end

    it "extends the class with Hooks module" do
      expect(test_class.singleton_class.included_modules).to include(SolidCallback::Hooks)
    end

    it "includes the MethodWrapper module in the class" do
      expect(test_class.included_modules).to include(SolidCallback::MethodWrapper)
    end

    it "initializes callback store on the class" do
      expect(test_class.instance_variable_get(:@_solid_callback_store)).to eq({
        before: {},
        after: {},
        around: {}
      })
    end
  end

  xdescribe "integration" do
    let(:test_class) do
      Class.new do
        include SolidCallback

        attr_reader :log

        def initialize
          @log = []
        end

        before_call :log_before
        after_call :log_after
        around_call :log_around

        def test_method(value)
          @log << "test_method(#{value})"
          return "result: #{value}"
        end

        private

        def log_before
          @log << "before"
        end

        def log_after
          @log << "after"
        end

        def log_around
          @log << "around_before"
          result = yield
          @log << "around_after: #{result}"
          result
        end
      end
    end

    it "runs callbacks in the correct order" do
      instance = test_class.new
      result = instance.test_method(42)

      expect(result).to eq("result: 42")
      expect(instance.log).to eq([
       "before",
       "around_before",
       "test_method(42)",
       "around_after: result: 42",
       "after"
     ])
    end
  end
end
