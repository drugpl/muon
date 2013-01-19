require 'test_helper'
require 'tmpdir'
require 'stringio'
require 'delorean'
require 'pathname'
require 'muon/init'

module Muon
  class InitTest < Test::Unit::TestCase
    include Delorean

    def setup
      @dir = Pathname.new(Dir.mktmpdir)
    end

    def test_initialized
      args             = Init::Arguments.new
      args.command_dir = @dir
      args.email       = "muon@example.org"

      i = Init.new(args)
      i.call

      assert File.directory?(@dir.join(".muon", "tracking"))
      assert File.file?(@dir.join(".muon", "config"))
    end

    def teardown
      FileUtils.remove_entry_secure(@dir)
    end
  end
end
