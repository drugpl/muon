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

    def to_s
      "parent #{parent_hash}\n" +
      "#{start_time},#{end_time}\n"
    end

    def self.from_s(str)
      parent_hash = str.lines.to_a[0].sub(/^parent /, "").strip
      parent_hash = nil if parent_hash == ""
      start_time, end_time = *str.lines.to_a[1].strip.split(",")
      new(Time.parse(start_time), Time.parse(end_time), parent_hash)
    end
  end
end
