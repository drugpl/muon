require 'test_helper'
require 'tmpdir'
require 'stringio'
require 'delorean'

class CliTest < Test::Unit::TestCase
  include Delorean

  def setup
    @dir = Dir.mktmpdir
    @home_dir = Dir.mktmpdir
    @output = StringIO.new
    @app = Muon::App.new(@dir, @home_dir, @output)
    @app.init_directory
  end

  def teardown
    FileUtils.remove_entry_secure(@dir)
    FileUtils.remove_entry_secure(@home_dir)
  end

  def test_init_initializes_only_once
    assert_raise(RuntimeError) { @app.init_directory }
  end

  def test_start_creates_tracking_file
    @app.start_tracking
    assert File.exists?("#{@dir}/.muon/current")
  end

  def test_start_fails_if_already_tracking
    @app.start_tracking
    assert_raise(RuntimeError) { @app.start_tracking }
  end

  def test_stop_stops_and_creates_history_entry
    @app.start_tracking
    @app.stop_tracking
    assert ! File.exists?("#{@dir}/.muon/current")
    assert File.exists?("#{@dir}/.muon/HEAD")
  end

  def test_stop_fails_if_not_tracking_yet
    assert_raise(RuntimeError) { @app.stop_tracking }
  end

  def test_abort_stop_and_does_not_create_entry
    @app.start_tracking
    @app.abort_tracking
    assert ! File.exists?("#{@dir}/.muon/current")
    assert ! File.exists?("#{@dir}/.muon/HEAD")
  end

  def test_commit_creates_history_entry
    @app.commit_entry("00:01", "00:05")
    assert File.exists?("#{@dir}/.muon/HEAD")
  end

  def test_status_reports_whether_running
    @app.show_status
    assert_equal "Time tracking is stopped.\n", @output.string.lines.to_a[0]

    @app.start_tracking
    reset_output
    @app.show_status
    assert_equal "Time tracking is running since 0 seconds.\n", @output.string.lines.to_a[0]
  end

  def test_status_reports_todays_total_time
    time_travel_to("yesterday 12:00") { @app.start_tracking }
    time_travel_to("yesterday 12:10") { @app.stop_tracking }
    time_travel_to("today 00:00") { @app.start_tracking }
    time_travel_to("today 00:05") { @app.stop_tracking }

    @app.show_status
    assert_equal "Time tracking is stopped.\nToday's total time is 5 minutes, 0 seconds.\n", @output.string
  end

  def test_total_calculates_total_time_for_a_day
    time_travel_to("2012-01-01 12:00") { @app.start_tracking }
    time_travel_to("2012-01-01 12:10") { @app.stop_tracking }
    time_travel_to("2012-01-02 00:00") { @app.start_tracking }
    time_travel_to("2012-01-02 00:05") { @app.stop_tracking }

    @app.show_total('2012-01-01')
    assert_equal "Total time on 2012-01-01 is 10 minutes, 0 seconds.\n", @output.string

    reset_output
    @app.show_total('2012-01-05')
    assert_equal "Total time on 2012-01-05 is 0 seconds.\n", @output.string
  end

  def test_log_lists_entries
    time_travel_to("2012-08-01") do
      @app.commit_entry("00:01", "00:05")
      @app.commit_entry("00:10", "00:20")
    end

    @app.show_log
    assert_equal "2012-08-01 00:10:00 +0200 - 2012-08-01 00:20:00 +0200 (10 minutes, 0 seconds)\n", @output.string.lines.to_a[0]
    assert_equal "2012-08-01 00:01:00 +0200 - 2012-08-01 00:05:00 +0200 (4 minutes, 0 seconds)\n", @output.string.lines.to_a[1]
    assert_equal 2, @output.string.lines.to_a.length

    reset_output
    @app.show_log(1)
    assert_equal "2012-08-01 00:10:00 +0200 - 2012-08-01 00:20:00 +0200 (10 minutes, 0 seconds)\n", @output.string.lines.to_a[0]
    assert_equal 1, @output.string.lines.to_a.length
  end

  def test_goal_for_month
    time_travel_to("2012-08-01") do
      @app.commit_entry("00:00", "00:05")
      @app.commit_entry("00:10", "00:20")

      test_command do
        @app.show_goal
        assert_equal "No goal has been set.\n", output
      end

      test_command do
        @app.set_goal('30:00:00')
        assert_equal "Setting goal for this month to 30 hours, 0 minutes, 0 seconds.\n", output
      end

      test_command do
        @app.show_goal
        assert_equal "The goal for this month is 30 hours, 0 minutes, 0 seconds.\n", output_lines[0]
        assert_equal "Time left to achieve this goal: 29 hours, 45 minutes, 0 seconds.\n", output_lines[1]
        assert_equal 2, output_lines.length
      end
    end
  end

  def test_config_setting_and_reading
    @app.set_config_option("alias.ci", "commit")

    @app.read_config_option("alias.ci")
    assert_equal "commit\n", @output.string

    reset_output
    @app.read_config_option("xxx.y")
    assert_equal "\n", @output.string
  end

  def test_dealiasify_replaces_aliases
    @app.set_config_option("alias.ci", "commit")
    assert_equal ["commit", "00:01", "00:05"], @app.dealiasify(["ci", "00:01", "00:05"])
  end

  def test_register_global_project
    @app.register_global_project
    assert_equal File.basename(@dir), @app.global_projects[0].name
    assert_equal @dir, @app.global_projects[0].path
  end

  private

  def test_command
    yield
    reset_output
  end

  def reset_output
    @output.string = ""
  end

  def output
    @output.string
  end

  def output_lines
    @output.string.lines.to_a
  end
end
