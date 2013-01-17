require 'fileutils'
require 'pathname'
require 'multi_json'

module Muon
  class Stop
    class Error < StandardError; end

    attr_accessor :project_dir, :email, :stop, :start, :metadata

    def initialize(project_dir, email, metadata = {}, stop = Time.now, start = get_start_time)
      @project_dir = project_dir
      @email       = email
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
      hash = metadata.merge({
        stop:     stop.utc.to_s,
        start:    start.utc.to_s,
        duration: duration
      })
    end

    def tracking_filename
      @tracking_filename ||= tracking_dir.join( start.strftime("%H%M%S.%L.json") )
    end

    def tracking_dir
      @tracking_dir ||= Pathname.new(project_dir).join("tracking", email, start.strftime("%Y/%m/%d") )
    end

    # TODO. Read from file created by muon start
    # TODO: Extract
    def get_start_time
      Time.now - 300
    end

    def branch_name
      "muon-#{email}"
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

