require "muon/history"

module Muon
  class Project
    attr_reader :path

    def initialize(path)
      @path = path
      @history = History.new(working_dir)
    end

    def name
      File.basename(path)
    end

    def working_dir
      File.join(path, ".muon")
    end

    def init_directory
      raise "Already initialized!" if Dir.exists?(working_dir)
      `git init --bare #{working_dir}`
    end

    def tracking?
      File.exists?(File.join(working_dir, "current"))
    end

    def start_tracking(start_time = nil)
      raise "Already tracking!" if tracking_file_exists?
      start_time ||= Time.now
      create_tracking_file(start_time.to_s)
    end

    def stop_tracking(end_time = nil)
      raise "Not tracking!" unless tracking_file_exists?
      start_time = Time.parse(read_tracking_file)
      end_time ||= Time.now
      commit_entry(start_time.to_s, end_time.to_s)
      delete_tracking_file
    end

    def abort_tracking
      raise "Not tracking!" unless tracking_file_exists?
      delete_tracking_file
    end

    def tracking_duration
      (Time.now - Time.parse(read_tracking_file)).to_i
    end

    def commit_entry(start_time, end_time)
      entry = Entry.new(start_time, end_time)
      history.append(entry)
    end

    def history_entries
      history.entries
    end

    def day_total_time(date = Time.now)
      date = date.strftime("%Y%m%d")
      history.entries.select { |e| e.start_time.strftime("%Y%m%d") == date }.map(&:duration).inject(&:+)
    end

    def month_total_time(date = Time.now)
      date = date.strftime("%Y%m")
      history.entries.select { |e| e.start_time.strftime("%Y%m") == date }.map(&:duration).inject(&:+)
    end

    def has_goal?
      goal_file_exists?
    end

    def goal
      read_goal_file.to_i
    end

    def goal=(seconds)
      write_goal_file(seconds.to_s)
    end

    def goal_remaining_time
      goal - month_total_time
    end

    private

    attr_reader :history

    def tracking_file
      File.join(working_dir, "current")
    end

    def tracking_file_exists?
      File.exists?(tracking_file)
    end

    def read_tracking_file
      File.open(tracking_file, "r") { |f| f.read }
    end

    def create_tracking_file(contents = "")
      File.open(tracking_file, "w") { |f| f.puts(contents) }
    end

    def delete_tracking_file
      File.unlink(tracking_file)
    end

    def goal_file
      File.join(working_dir, "goal")
    end

    def goal_file_exists?
      File.exists?(goal_file)
    end

    def read_goal_file
      File.open(goal_file, "r") { |f| f.read }
    end

    def write_goal_file(contents = "")
      File.open(goal_file, "w") { |f| f.puts(contents) }
    end
  end
end
