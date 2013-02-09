require 'fileutils'
require 'pathname'
require 'multi_json'

module Muon
  class Current

    class Error < StandardError; end

    attr_accessor :project_dir

    def initialize(project_dir)
      @project_dir = project_dir
    end

    def save(data)
      current_dir.mkpath
      raise Error, "Tracking already started" if current_filename.exist?
      current_filename.open("w") {|f| f.puts(string(data)) }
    end

    def read
      MultiJson.load(current_filename.read)
    end

    def ephemeral(&block)
      yield read
      current_filename.delete
    end

    private

    def string(data)
      MultiJson.dump(data, :pretty => true)
    end

    def current_filename
      @current_filename ||= current_dir.join("current")
    end

    def current_dir
      @current_dir ||= Pathname.new(project_dir)
    end

  end
end
