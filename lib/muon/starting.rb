require 'fileutils'
require 'pathname'
require 'multi_json'

require 'muon/current'

module Muon
  class Starting
    class Error < StandardError; end

    attr_accessor :project_dir, :start, :metadata

    def initialize(project_dir, metadata = {}, start = get_start_time)
      @project_dir = project_dir
      @metadata    = metadata
      @start       = start
    end

    def call
      Current.new(project_dir).save(data)
    end

    private

    def get_start_time
      Time.now
    end

    def data
      {
        start: start.utc.to_s,
      }.merge(metadata)
    end
  end
end
