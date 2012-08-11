require "yaml"

module Muon
  class Config
    attr_reader :local_file, :global_file

    def initialize(local_file, global_file)
      @local_file, @global_file = local_file, global_file
    end

    def get_option(key)
      get_local_option(key) || get_global_option(key)
    end

    def get_local_option(key)
      get_option_from_file(local_file, key)
    end

    def set_local_option(key, value)
      set_option_in_file(local_file, key, value)
    end

    alias :set_option :set_local_option

    def get_global_option(key)
      get_option_from_file(global_file, key)
    end

    def set_global_option(key, value)
      set_option_in_file(global_file, key, value)
    end

    private

    def get_option_from_file(file, key)
      config = read_config_file(file) || {}
      group, name = split_config_key(key)
      config[group] ||= {}
      config[group][name]
    end

    def set_option_in_file(file, key, value)
      config = read_config_file(file) || {}
      group, name = *key.split(".", 2)
      config[group] ||= {}
      config[group][name] = value
      write_config_file(file, config)
    end

    def read_config_file(file)
      return nil unless File.exists?(file)
      YAML.load_file(file)
    end

    def write_config_file(file, config)
      File.open(file, "w") { |f| f.write YAML.dump(config) }
    end

    def split_config_key(key)
      parts = key.split(".")
      group = parts.slice(0, parts.length - 1).join(".")
      name = parts.last
      [group, name]
    end
  end
end
