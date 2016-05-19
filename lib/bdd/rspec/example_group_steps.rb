module Bdd
  module RSpec
    module ExampleGroupSteps

      module ClassMethods
        def define_bdd_step(*names)
          bdd_steps.concat(names)
          names.each do |name|
            define_method(name) do |msg, &block|
              bdd_step([name, msg], &block)
            end
          end
        end
        def bdd_steps
          @bdd_steps
        end
      end

      def self.included(base)
        # add the `define_bdd_step` and `bdd_steps` class methods
        base.extend ClassMethods
        # initialize empty bdd_steps
        base.instance_variable_set(:@bdd_steps, [])
        # step needs access to the @bdd_steps - but it is not visible when extend is used, especially not as @@bdd_steps
        base.send(:define_method, :bdd_steps) { base.bdd_steps }
      end

    private

      def bdd_step(prefix_and_text, &block)
        unless using_bdd_formatter?
          yield if block_given?
          return
        end

        if
          ::RSpec.current_example.metadata[:bdd_prefix_max_length].nil?
        then
          ::RSpec.current_example.metadata[:bdd_prefix_max_length] = bdd_steps.map(&:length).max
        end

        @is_during_rspec_step ||= 0
        if
          block_given?
        then
          add_bdd_message prefix_and_text
          # increase the counter so any nested messages are ignored
          @is_during_rspec_step += 1
          yield
          @is_during_rspec_step -= 1
        else
          add_bdd_message "SKIPPED #{prefix_and_text}"
        end
        return :bdd
      end

      # uses only the top message
      def add_bdd_message(text)
        bdd_step_messages << text if @is_during_rspec_step == 0
      end

      def bdd_step_messages
        ::RSpec.current_example.metadata[:bdd_step_messages]
      end

      def using_bdd_formatter?
        !bdd_step_messages.nil?
      end

    end
  end
end