require 'test_helper'
require 'tmpdir'
require 'stringio'
require 'delorean'
require 'muon/init'

module Muon
  class InitTest < Test::Unit::TestCase
    include Delorean

    def setup
      @dir = Dir.mktmpdir
    end

    def test_initialized
      i = Init.new(@dir, @dir, "muon@example.org")
      i.call
      assert File.directory?(File.join(@dir, ".muon"))
    end

    def teardown
      #FileUtils.remove_entry_secure(@dir)
    end
  end
end
