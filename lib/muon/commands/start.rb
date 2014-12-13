require 'muon/starting'

module Muon
  module Commands
    class Start
      def initialize(project_dir, global_options, options, args)
        @project_dir    = project_dir
        @global_options = global_options
        @options        = options
        @args           = args
      end

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
