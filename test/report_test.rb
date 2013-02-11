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
        {"ticket" => "#100", "email" => "robert"},
        {"ticket" => "#100", "email" => "robert"},
        {"ticket" => "#234", "email" => "robert"},

        {"ticket" => "#100", "email" => "janek"},
        {"ticket" => "#234", "email" => "janek"},
        {"ticket" => "#234", "email" => "janek"},
      ].each do |meta|
        Commit.new(@muon, meta, t = Time.now, t - 300).call
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
        assert_equal 300.00,    row[:sum]
      end

      ticket_email.to_a.third.tap do |row|
        assert_equal "#234",    row[:ticket]
        assert_equal "janek",   row[:email]
        assert_equal 300.00,    row[:sum]
      end

      ticket_email.to_a.fourth.tap do |row|
        assert_equal "#234",    row[:ticket]
        assert_equal "robert",  row[:email]
        assert_equal 300.00,    row[:sum]
      end

      ticket.to_a.first.tap do |row|
        assert_equal "#100",    row[:ticket]
        assert_equal 600.00,    row[:sum]
      end

      ticket.to_a.second.tap do |row|
        assert_equal "#234",    row[:ticket]
        assert_equal 600.00,    row[:sum]
      end

      total.to_a.first.tap do |row|
        assert_equal 1200.00,    row[:sum]
      end


      #return

      puts
      puts "XX"

      lines    = []
      blah     = result.clone
      relation = blah.shift
      headers  = groups.map {|g| relation[g] }
      puts headers.inspect
      all      = headers + [ relation[:sum] ]
      puts all.inspect

      relation.each do |tuple|
        line = tuple.project(all).to_ary
        lines << line
      end

      loop do
        headers.pop
        relation = blah.shift
        break unless headers.present?
        relation.each do |tuple|
          found = nil
          new   = tuple.project(all).to_ary
          lines.each_with_index do |line, index|
            if line.first(headers.size) == new.first(headers.size)
              found = index
            end
          end

          lines.insert(found + 1, new)
        end

      end

      result.last.each{|t| lines << t.project(all).to_ary}
      puts lines.inspect
      require 'hirb'
      puts Hirb::Helpers::AutoTable.render(lines)
    end

    def teardown
      puts @dir
      #FileUtils.remove_entry_secure(@dir)
    end
  end
end
