require 'ostruct'

module Muon
  class ConfigContext
    def config
      @config ||= OpenStruct.new
    end

    def muon
      self
    end

    def revenue
      # TODO: Implement it
      0
    end

    def self.get_config(project_dir)
      context = ConfigContext.new
      ruby    = Pathname.new(project_dir).join("config").read
      context.instance_eval(ruby)
      context
    end
  end
end
