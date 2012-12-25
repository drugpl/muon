require "time"
require "chronic_duration"
require "muon/config"
require "muon/entry"
require "muon/format"
require "muon/project"

module Muon
  class App
    def initialize(working_dir, home_dir = ENV["HOME"], output = $stdout)
      @working_dir = working_dir
      @home_dir = home_dir
      @output = output
      @project = Project.new(working_dir)
      @config = Config.new(config_file, global_config_file)
    end

    attr_reader :project

    def init_directory
      project.init_directory
    end

    def start_tracking(start_time = nil)
      start_time = Time.parse(start_time) if start_time
      project.start_tracking(start_time)
    end

    def stop_tracking(end_time = nil)
      end_time = Time.parse(end_time) if end_time
      project.stop_tracking(end_time)
    end

    def abort_tracking
      project.abort_tracking
    end

    def commit_entry(start_time, end_time)
      start_time = Time.parse(start_time)
      end_time = Time.parse(end_time)
      project.commit_entry(start_time, end_time)
    end

    def show_status
      if @project.tracking?
        @output.puts "Time tracking is running since #{Format.duration @project.tracking_duration}."
      else
        @output.puts "Time tracking is stopped."
      end
      @output.puts "Today's total time is #{Format.duration @project.day_total_time(Time.now)}."
    end

    def show_total(date = nil)
      if date.nil?
        date = Time.now
      else
        date = Time.parse(date)
      end
      @output.puts "Total time on #{date.strftime('%Y-%m-%d')} is #{Format.duration @project.day_total_time(date)}."
    end

    def show_log(limit = nil)
      entries = @project.history_entries
      entries = entries.take(limit) if limit
      entries.each do |entry|
        @output.puts "#{entry.start_time} - #{entry.end_time} (#{Format.duration entry.duration})"
      end
    end

    def show_goal
      if project.has_goal?
        @output.puts "The goal for this month is #{Format.duration project.goal}."
        @output.puts "Time left to achieve this goal: #{Format.duration project.goal_remaining_time}."
      else
        @output.puts "No goal has been set."
      end
    end

    def set_goal(duration)
      duration = ChronicDuration.parse(duration)
      project.goal = duration
      @output.puts "Setting goal for this month to #{Format.duration duration}."
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
      File.open(global_projects_file, "r") do |f|
        f.lines.to_a.map(&:strip).map { |path| Project.new(path) }
      end
    end

    def register_global_project
      File.open(global_projects_file, "a") { |f| f << "#{@working_dir}\n" }
    end

    private

    # attr_reader :history

    def config_file
      File.join(project.working_dir, "plainconfig")
    end

    def global_config_file
      File.join(@home_dir, ".muonconfig") if @home_dir
    end

    def global_projects_file
      File.join(@home_dir, ".muonprojects") if @home_dir
    end
  end
end
