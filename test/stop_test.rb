require 'test_helper'
require 'tmpdir'
require 'multi_json'
require 'muon/init'
require 'muon/stop'

module Muon
  class InitTest < Test::Unit::TestCase

    def setup
      @dir  = Pathname.new(Dir.mktmpdir)
      i = Init.new(@dir, @dir, @email = "muon@example.org")
      i.call
      @muon = @dir.join ".muon"
    end

    def test_stop_generates_tracking_entry
      s = Stop.new(@muon, @email, {key: "value"})
      s.call
      entry = Dir.glob( @muon.join("tracking", @email, Time.now.year.to_s, "%02d" % Time.now.month, "%02d" % Time.now.day, '*') ).first
      entry = Pathname.new(entry)
      hash = MultiJson.load(entry.read)
      assert hash['stop']
      assert hash['start']
      assert hash['duration']
      assert hash['key']
    end

    def teardown
      FileUtils.remove_entry_secure(@dir)
    end
  end
end
