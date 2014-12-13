module Muon
  module Commands
    class Command
      def initialize(project_dir, globals, options, args)
        @project_dir = project_dir
        @globals     = globals
        @options     = options
        @args        = args
      end

      def call
      end
    end
  end
end
