require 'test_helper'
require 'tmpdir'
require 'multi_json'
require 'muon/init'
require 'muon/commit'
require 'muon/report'
require 'active_support/all'

module Muon
  class ReportTest < Test::Unit::TestCase

    def setup
      @dir  = Pathname.new(Dir.mktmpdir)
      @muon = @dir.join ".muon"

      args             = Init::Arguments.new
      args.command_dir = @dir
      args.email       = "muon@example.org"
      i = Init.new(args)
      i.call

      [
        {"ticket" => "#100"},
        {"ticket" => "#100"},
        {"ticket" => "#234"}
      ].each do |meta|
        Commit.new(@muon, meta, Time.now, Time.now - 300).call
      end
    end

    def test_report_test
      r = Report.new(@muon, 1.day.ago, 1.day.from_now, [], [:ticket])
      result = r.call

      result.each do |r|
        r.each do |t|
          puts t.inspect
        end
        puts
      end
    end

    def teardown
      puts @dir
      #FileUtils.remove_entry_secure(@dir)
    end
  end
end
