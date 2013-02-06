require 'fileutils'
require 'pathname'
require 'multi_json'

module Muon
  class Start
    class Error < StandardError; end

    attr_accessor :project_dir, :start, :metadata

    def initialize(project_dir, metadata = {}, start = get_start_time)
      @project_dir = project_dir
      @metadata    = metadata
      @start       = start
    end

    def call
      current_dir.mkpath
      raise Error, "Tracking already started" if current_filename.exist?
      current_filename.open("w") {|f| f.puts(string) }
    end

    private

    def get_start_time
      Time.now
    end

    def string
      MultiJson.dump(data, :pretty => true)
    end

    def data
      {
        start: start.utc.to_s,
      }.merge(metadata)
    end

    def current_filename
      @current_filename ||= current_dir.join("current")
    end

    def current_dir
      @current_dir ||= Pathname.new(project_dir)
    end

  end
end
