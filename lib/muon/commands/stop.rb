require 'muon/commit'
require 'muon/current'
require 'muon/commands/command'

module Muon
  module Commands
    class Stop < Command
      def call
        Muon::Current.new(@project_dir).ephemeral do |metadata|
          start       = Time.parse( metadata.delete('start') )
          Muon::Commit.new(@project_dir, metadata, Time.now, start).call
        end
      end
    end
  end
end
