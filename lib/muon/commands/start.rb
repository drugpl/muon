require 'muon/starting'
require 'muon/commands/command'

module Muon
  module Commands
    class Start < Command
      def call
        metadata = @args.inject({}) do |hash, arg|
          key, value = arg.split(":", 2)
          raise 'Metadata must follow "key:value" convention' if key.nil? || value.nil? || key.empty? || value.empty?
          hash[key] = value
          hash
        end

        Muon::Starting.new(@project_dir, metadata).call
      end
    end
  end
end
