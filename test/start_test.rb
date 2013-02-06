require 'test_helper'
require 'tmpdir'
require 'multi_json'
require 'muon/init'
require 'muon/start'

module Muon
  class StartTest < Test::Unit::TestCase

    def setup
      @dir  = Pathname.new(Dir.mktmpdir)

      args             = Init::Arguments.new
      args.command_dir = @dir
      args.email       = "muon@example.org"
      i = Init.new(args)
      i.call

      @muon = @dir.join ".muon"
    end

    def test_start_stores_metadata
      s = Start.new(@muon, {key: "value"})
      s.call
      entry = @muon.join("current")
      entry = Pathname.new(entry)
      hash  = MultiJson.load(entry.read)
      assert hash['start']
      assert hash['key']
    end

    def teardown
      FileUtils.remove_entry_secure(@dir)
    end
  end
end
