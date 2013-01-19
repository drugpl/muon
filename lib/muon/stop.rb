require 'fileutils'
require 'pathname'
require 'multi_json'

module Muon
  class Stop
    class ConfigContext
      require 'ostruct'

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
    end

    class Error < StandardError; end

    attr_accessor :project_dir, :stop, :start, :metadata

    def initialize(project_dir, metadata = {}, stop = Time.now, start = get_start_time)
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
        hash.merge!(encrypted_attributes)
        # TODO: Store encrypted
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
      @muon ||= begin
        context = ConfigContext.new
        ruby    = Pathname.new(project_dir).join("config").read
        context.instance_eval(ruby)
        context
      end
    end

    def tracking_filename
      @tracking_filename ||= tracking_dir.join( start.strftime("%H%M%S.%L.json") )
    end

    def tracking_dir
      @tracking_dir ||= Pathname.new(project_dir).join("tracking", start.strftime("%Y/%m/%d") )
    end

    # TODO. Read from file created by muon start
    # TODO: Extract
    def get_start_time
      Time.now - 300
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

