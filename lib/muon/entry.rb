require "time"

module Muon
  class Entry
    attr_reader :start_time, :end_time, :parent_hash

    def initialize(start_time, end_time, parent_hash = nil)
      @start_time, @end_time = start_time, end_time
      @parent_hash = parent_hash
    end

    def duration
      (end_time - start_time).to_i
    end

    def with_parent_hash(new_parent_hash)
      raise "Already have parent hash" if parent_hash
      Entry.new(start_time, end_time, new_parent_hash)
    end

    def self.from_commit(commit)
      lines = commit.lines.map(&:strip)
      meta_lines = lines.take_while { |line| line != "" }
      body_lines = lines.drop_while { |line| line != "" }.drop(1)
      parent_hash = meta_lines.grep(/^parent /).map { |line| line.sub(/^parent /, '') }.first
      start_time, end_time = *body_lines.first.strip.split(',')
      new(Time.parse(start_time), Time.parse(end_time), parent_hash)
    end
  end
end
