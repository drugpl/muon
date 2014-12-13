require 'fileutils'
require 'pathname'
require 'time'
require 'multi_json'
require 'securerandom'
require 'muon/config_context'

module Muon
  class Commit
    class Error < StandardError; end

    attr_accessor :project_dir, :stop, :start, :metadata

    def initialize(project_dir, metadata, stop, start)
      @project_dir = project_dir
      @start       = start
      @stop        = stop
      @metadata    = metadata
    end

    def call
      ensure_branch
      FileUtils.mkdir_p(tracking_dir)
      File.open(tracking_filename, "w") {|f| f.puts(string) }
      Dir.chdir(project_dir) do
        puts `git add #{tracking_filename}`
        puts `git commit -m 'Working really hard sir'`
      end
    end

    def string
      MultiJson.dump(data, :pretty => true)
    end

    def data
      duration = stop - start
      raise Error, "wat..." if duration <= 0
      hash = autodata.merge(metadata).merge({
        stop:     stop.utc.to_s,
        start:    start.utc.to_s,
        duration: duration
      })
    end

    def autodata
      @autodata ||= begin
        hash   = {}
        hash.merge!(attributes)
        # TODO: Store encrypted
        # hash.merge!(encrypted_attributes)
        hash
      end
    end


    def attributes
      if muon.config.attributes
        muon.config.attributes.call(@start, @stop)
      else
        {}
      end
    end

    def encrypted_attributes
      if muon.config.encrypted_attributes
        muon.config.encrypted_attributes.call(@start, @stop)#.tap{|x| puts(x.inspect)}
        # TODO: Encrypt them
        {}
      else
        {}
      end
    end

    def muon
      @muon ||= Muon::ConfigContext.get_config(project_dir)
    end

    def tracking_filename
      @tracking_filename ||= tracking_dir.join( start.strftime("%H.%M.%S.") + SecureRandom.hex(2) + ".json" )
    end

    def tracking_dir
      @tracking_dir ||= Pathname.new(project_dir).join("tracking", start.strftime("%Y/%m/%d") )
    end

    def branch_name
      muon.config.branch
    end

    def ensure_branch
      raise Error, "incorrect branch" unless correct_branch?
    end

    def correct_branch?
      Dir.chdir(project_dir) do
        `git rev-parse --abbrev-ref HEAD`.strip == branch_name
      end
    end
  end
end

