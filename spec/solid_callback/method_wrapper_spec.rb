RSpec.describe SolidCallback::MethodWrapper do
  let(:test_class) do
    Class.new do
      extend SolidCallback::Core
      extend SolidCallback::Hooks
      include SolidCallback::MethodWrapper

      class << self
        attr_accessor :_solid_callback_store
      end

      self._solid_callback_store = {
        before: {},
        after: {},
        around: {}
      }

      def test_method(value)
        "test: #{value}"
      end

      alias_method :_solid_callback_original_test_method, :test_method
    end
  end

  describe "#run_callbacks" do
    let(:instance) { test_class.new }

    before do
      # Define callback methods
      test_class.class_eval do
        def callback1
          @called ||= []
          @called << :callback1
        end

        def callback2
          @called ||= []
          @called << :callback2
        end

        def called
          @called ||= []
        end
      end

      # Set up callback store
      test_class._solid_callback_store = {
        before: {
          callback1: { method: :callback1, only: [:all], except: [] },
          callback2: { method: :callback2, only: [:test_method], except: [] }
        },
        after: {},
        around: {}
      }
    end

    it "runs applicable callbacks" do
      instance.send(:run_callbacks, :before, :test_method)

      expect(instance.called).to eq([:callback1, :callback2])
    end

    it "skips callbacks that don't apply" do
      # Make callback2 not applicable
      test_class._solid_callback_store[:before][:callback2][:only] = [:other_method]

      instance.send(:run_callbacks, :before, :test_method)

      expect(instance.called).to eq([:callback1])
    end

    it "does nothing when no callbacks exist" do
      test_class._solid_callback_store[:before] = {}

      expect {
        instance.send(:run_callbacks, :before, :test_method)
      }.not_to raise_error
    end
  end

  describe "#run_around_callbacks" do
    let(:instance) { test_class.new }

    context "with no around callbacks" do
      it "calls the original method directly" do
        expect(instance).to receive(:_solid_callback_original_test_method).with(42)

        instance.send(:run_around_callbacks, :test_method, [42], nil)
      end
    end

    context "with around callbacks" do
      before do
        # Define callback methods
        test_class.class_eval do
          def around_callback1
            @called ||= []
            @called << :around1_before
            result = yield
            @called << :around1_after
            result
          end

          def around_callback2
            @called ||= []
            @called << :around2_before
            result = yield
            @called << :around2_after
            result
          end

          def called
            @called ||= []
          end
        end

        # Set up callback store
        test_class._solid_callback_store = {
          before: {},
          after: {},
          around: {
            around_callback1: { method: :around_callback1, only: [:all], except: [] },
            around_callback2: { method: :around_callback2, only: [:test_method], except: [] }
          }
        }
      end

      it "chains around callbacks correctly" do
        allow(instance).to receive(:collect_applicable_around_callbacks).and_return([:around_callback1, :around_callback2])
        allow(instance).to receive(:_solid_callback_original_test_method).and_return("original result")

        result = instance.send(:run_around_callbacks, :test_method, [42], nil)

        expect(result).to eq("original result")
        expect(instance.called).to eq([
                                        :around1_before,
                                        :around2_before,
                                        :around2_after,
                                        :around1_after
                                      ])
      end
    end
  end

  describe "#collect_applicable_around_callbacks" do
    let(:instance) { test_class.new }

    before do
      # Set up callback store with some around callbacks
      test_class._solid_callback_store = {
        before: {},
        after: {},
        around: {
          around1: { method: :around1, only: [:all], except: [] },
          around2: { method: :around2, only: [:test_method], except: [] },
          around3: { method: :around3, only: [:other_method], except: [] }
        }
      }
    end

    it "collects applicable callbacks" do
      allow(test_class).to receive(:callback_applicable?).and_return(true, true, false)

      callbacks = instance.send(:collect_applicable_around_callbacks, :test_method)

      expect(callbacks).to eq([:around1, :around2])
    end

    it "returns empty array when no around callbacks exist" do
      test_class._solid_callback_store[:around] = {}

      callbacks = instance.send(:collect_applicable_around_callbacks, :test_method)

      expect(callbacks).to eq([])
    end
  end

  describe "#execute_around_chain" do
    let(:instance) { test_class.new }

    before do
      # Define callback methods
      test_class.class_eval do
        def around1
          @log ||= []
          @log << "around1_before"
          result = yield
          @log << "around1_after"
          result
        end

        def around2
          @log ||= []
          @log << "around2_before"
          result = yield
          @log << "around2_after"
          result
        end

        def log
          @log ||= []
        end
      end
    end

    it "executes callbacks in correct order" do
      allow(instance).to receive(:_solid_callback_original_test_method).with(42).and_return("result")

      result = instance.send(:execute_around_chain, [:around1, :around2], 0, :test_method, [42], nil)

      expect(result).to eq("result")
      expect(instance.log).to eq([
                                   "around1_before",
                                   "around2_before",
                                   "around2_after",
                                   "around1_after"
                                 ])
    end

    it "calls original method at end of chain" do
      expect(instance).to receive(:_solid_callback_original_test_method).with(42).and_return("result")

      instance.send(:execute_around_chain, [], 0, :test_method, [42], nil)
    end
  end
end