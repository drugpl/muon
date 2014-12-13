require 'muon/current'
require 'muon/commit'
require 'muon/format'
require 'muon/report'
require 'muon/muon_path_finder'

module Muon
  module Commands
    class Status
      def call
        project_dir = Muon::MuonPathFinder.new.call

        current          = Muon::Current.new(project_dir)
        current_duration = get_current_duration(project_dir, current)
        print_current_tracking(current, current_duration)

        from      = Time.now.beginning_of_day
        to        = Time.now.end_of_day
        today_sum = get_period_time_sum(project_dir, from, to) + current_duration
        print_today_tracking(today_sum)

        from     = Time.now.beginning_of_week
        to       = Time.now.end_of_week
        week_sum = get_period_time_sum(project_dir, from, to) + current_duration
        print_week_tracking(week_sum)

        from      = Time.now.beginning_of_month
        to        = Time.now.end_of_month
        month_sum = get_period_time_sum(project_dir, from, to) + current_duration
        print_month_tracking(month_sum)
      end

      def get_period_time_sum(project_dir, from, to)
        result    = Muon::Report.new(project_dir, from, to, nil, []).call
        result.first.to_a.first[:sum] rescue 0
      end

      def get_current_duration(project_dir, current)
        if current.tracking?
          metadata  = current.read
          start     = Time.parse( metadata.delete('start') )
          commit    = Muon::Commit.new(project_dir, metadata, Time.now, start)
          data      = commit.data
          duration  = data[:duration]
        end
        duration.to_f
      end

      def print_current_tracking(current, current_duration)
        if current.tracking?
          puts "Tracking: #{Muon::Format.duration(current_duration)}."
        else
          puts "Tracking: Stopped"
        end
      end

      def print_today_tracking(today_duration)
        puts "Today:    #{Muon::Format.duration(today_duration)}."
      end

      def print_week_tracking(today_duration)
        puts "Week:     #{Muon::Format.duration(today_duration)}."
      end

      def print_month_tracking(month_duration)
        puts "Month:    #{Muon::Format.duration(month_duration)}."
      end
    end
  end
end
