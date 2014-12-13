require 'muon/commands/command'

module Muon
  module Commands
    class Branch < Command
      def call
        Dir.chdir(@project_dir) do
          puts `git branch`
        end
      end
    end
  end
end
