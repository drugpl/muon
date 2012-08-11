require "time"
require "muon/config"
require "muon/entry"
require "muon/history"

module Muon
  class App
    def initialize(working_dir, home_dir = ENV["HOME"], output = $stdout)
      @working_dir = working_dir;
      @home_dir = home_dir;
      @history = History.new(muon_dir)
      @output = output
      @config = Config.new(config_file, global_config_file)
    end

    def init_directory(*args)
      raise "Already initialized!" if Dir.exists?(muon_dir)
      Dir.mkdir(muon_dir)
      Dir.mkdir(File.join muon_dir, "objects")
    end

    def start_tracking(start_time = nil)
      raise "Already tracking!" if tracking_file_exists?
      start_time = start_time.nil? ? Time.now : Time.parse(start_time)
      create_tracking_file(start_time.to_s)
    end

    def stop_tracking(end_time = nil)
      raise "Not tracking!" unless tracking_file_exists?
      start_time = Time.parse(read_tracking_file)
      end_time = end_time.nil? ? Time.now : Time.parse(end_time)
      commit_entry(start_time.to_s, end_time.to_s)
      delete_tracking_file
    end

    def abort_tracking
      raise "Not tracking!" unless tracking_file_exists?
      delete_tracking_file
    end

    def commit_entry(start_time, end_time)
      start_time = Time.parse(start_time)
      end_time = Time.parse(end_time)
      entry = Entry.new(start_time, end_time)
      history.append(entry)
    end

    def show_status
      if tracking_file_exists?
        elapsed_seconds = Time.now - Time.parse(read_tracking_file)
        @output.puts "Time tracking is running since #{format_duration elapsed_seconds.to_i}."
      else
        @output.puts "Time tracking is stopped."
      end
      @output.puts "Today's total time is #{format_duration today_total_time}."
    end

    def show_log(limit = nil)
      entries = history.entries
      entries = entries.take(limit) if limit
      entries.each do |entry|
        @output.puts "#{entry.start_time} - #{entry.end_time} (#{format_duration entry.duration})"
      end
    end

    def dealiasify(args)
      dealiased = @config.get_option("alias.#{args.first}")
      if dealiased
        [dealiased] + args.drop(1)
      else
        args
      end
    end

    def read_config_option(key, options = {})
      if options[:global]
        @output.puts @config.get_global_option(key)
      else
        @output.puts @config.get_option(key)
      end
    end

    def set_config_option(key, value, options = {})
      if options[:global]
        @config.set_global_option(key, value)
      else
        @config.set_option(key, value)
      end
    end

    def global_projects
      File.open(global_projects_file, "r") { |f| f.lines.to_a.map(&:strip) }
    end

    def register_global_project
      File.open(global_projects_file, "a") { |f| f << "#{@working_dir}\n" }
    end

    private

    attr_reader :history

    def tracking_file
      File.join(muon_dir, "current")
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

    def muon_dir
      File.join(@working_dir, ".muon")
    end

    def config_file
      File.join(muon_dir, "config")
    end

    def global_config_file
      File.join(@home_dir, ".muonconfig") if @home_dir
    end

    def global_projects_file
      File.join(@home_dir, ".muonprojects") if @home_dir
    end

    def today_total_time
      today = Time.now.strftime("%Y%m%d")
      history.entries.select { |e| e.start_time.strftime("%Y%m%d") == today }.map(&:duration).inject(&:+)
    end

    def format_duration(seconds)
      seconds ||= 0
      minutes = seconds / 60
      if minutes == 0
        "#{seconds} seconds"
      else
        seconds = seconds % 60
        hours = minutes / 60
        if hours == 0
          "#{minutes} minutes, #{seconds} seconds"
        else
          minutes = minutes % 60
          "#{hours} hours, #{minutes} minutes, #{seconds} seconds"
        end
      end
    end
  end
end
