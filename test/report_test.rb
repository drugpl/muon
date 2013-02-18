require 'test_helper'
require 'tmpdir'
require 'multi_json'
require 'muon/init'
require 'muon/commit'
require 'muon/report'
require 'muon/report_table'
require 'active_support/all'

module Muon
  class ReportTest < Test::Unit::TestCase

    attr_reader :now

    def setup
      @now = Time.now
      @dir  = Pathname.new(Dir.mktmpdir)
      @muon = @dir.join ".muon"

      args             = Init::Arguments.new
      args.command_dir = @dir
      args.email       = "muon@example.org"
      i = Init.new(args)
      i.call

      [
        {"ticket" => "#100", "email" => "robert"},
        {"ticket" => "#100", "email" => "robert"},
        {"ticket" => "#234", "email" => "robert"},

        {"ticket" => "#100", "email" => "janek"},
        {"ticket" => "#234", "email" => "janek"},
        {"ticket" => "#234", "email" => "janek"},
      ].each_with_index do |meta, index|
        t   = Time.new(now.year, now.month, now.day, index)
        Commit.new(@muon, meta, t + 300, t).call
      end
    end

    def test_report_filtering
      groups = []

      from   = Time.new(now.year, now.month, now.day, 0)
      to     = Time.new(now.year, now.month, now.day, 3)

      r      = Report.new(@muon, from, to, [], groups)
      result = r.call
      puts result.inspect

      result.first.to_a.first.tap do |row|
        assert_equal 900.00,    row[:sum]
      end
    end

    def test_report_test
      groups = [:ticket, :email]
      r      = Report.new(@muon, 1.day.ago, 1.day.from_now, [], groups)
      result = r.call


      assert_equal 3, result.size
      ticket_email = result.first
      ticket       = result.second
      total        = result.third

      ticket_email.to_a.first.tap do |row|
        assert_equal "#100",    row[:ticket]
        assert_equal "janek",   row[:email]
        assert_equal 300.00,    row[:sum]
      end

      ticket_email.to_a.second.tap do |row|
        assert_equal "#100",    row[:ticket]
        assert_equal "robert",  row[:email]
        assert_equal 600.00,    row[:sum]
      end

      ticket_email.to_a.third.tap do |row|
        assert_equal "#234",    row[:ticket]
        assert_equal "janek",   row[:email]
        assert_equal 600.00,    row[:sum]
      end

      ticket_email.to_a.fourth.tap do |row|
        assert_equal "#234",    row[:ticket]
        assert_equal "robert",  row[:email]
        assert_equal 300.00,    row[:sum]
      end

      ticket.to_a.first.tap do |row|
        assert_equal "#100",    row[:ticket]
        assert_equal 900.00,    row[:sum]
      end

      ticket.to_a.second.tap do |row|
        assert_equal "#234",    row[:ticket]
        assert_equal 900.00,    row[:sum]
      end

      total.to_a.first.tap do |row|
        assert_equal 1800.00,    row[:sum]
      end
    end

    def test_report_table
      groups = [:ticket, :email]
      result = Report.new(@muon, 1.day.ago, 1.day.from_now, [], groups).call
      table  = ReportTable.new(result, groups).table

      table.shift.tap do |row|
        assert_equal "#100",    row.first
        assert_equal "janek",   row.second
        assert_equal 300.00,    row.third
      end

      table.shift.tap do |row|
        assert_equal "#100",    row.first
        assert_equal "robert",  row.second
        assert_equal 600.00,    row.third
      end

      table.shift.tap do |row|
        assert_equal "#100",    row.first
        assert_equal nil,       row.second
        assert_equal 900.00,    row.third
      end

      table.shift.tap do |row|
        assert_equal "#234",    row.first
        assert_equal "janek",   row.second
        assert_equal 600.00,    row.third
      end

      table.shift.tap do |row|
        assert_equal "#234",    row.first
        assert_equal "robert",  row.second
        assert_equal 300.00,    row.third
      end

      table.shift.tap do |row|
        assert_equal "#234",    row.first
        assert_equal nil,       row.second
        assert_equal 900.00,    row.third
      end

      table.shift.tap do |row|
        assert_equal nil,       row.first
        assert_equal nil,       row.second
        assert_equal 1800.00,   row.third
      end
    end

    def teardown
      puts @dir
      #FileUtils.remove_entry_secure(@dir)
    end
  end
end
