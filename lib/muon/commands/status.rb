require 'muon/current'
require 'muon/commit'
require 'muon/format'
require 'muon/reporting'
require 'muon/muon_path_finder'
require 'muon/config_context'

module Muon
  module Commands
    class Status
      def initialize(project_dir)
        @project_dir = project_dir
        @muon        = ConfigContext.get_config(project_dir)
      end

      attr_reader :muon

      def call
        current          = Muon::Current.new(@project_dir)
        current_duration = get_current_duration(current)
        print_current_tracking(current, current_duration)

        from          = Time.now.beginning_of_day
        to            = Time.now.end_of_day
        today_sum     = get_period_time_sum(from, to) + current_duration
        today_target  = muon.config.daily_hours.call(Date.today)
        today_percent = ((today_sum / 3600.0) / today_target) * 100
        print_today_tracking(today_sum, today_percent)

        from         = Time.now.beginning_of_week
        to           = Time.now.end_of_week
        week_sum     = get_period_time_sum(from, to) + current_duration
        week_target  = muon.config.weekly_hours.call(Date.today.beginning_of_week)
        week_percent = ((week_sum / 3600.0) / week_target) * 100
        print_week_tracking(week_sum, week_percent)

        from          = Time.now.beginning_of_month
        to            = Time.now.end_of_month
        month_sum     = get_period_time_sum(from, to) + current_duration
        month_target  = muon.config.monthly_hours.call(Date.today.beginning_of_month)
        month_percent = ((month_sum / 3600.0) / month_target) * 100
        print_month_tracking(month_sum, month_percent)
      end

      def get_period_time_sum(from, to)
        result   = Muon::Reporting.new(@project_dir, from, to, nil, [], false).call
        time_sum = result.first.to_a.first[:sum] rescue 0
        time_sum
      end

      def get_current_duration(current)
        if current.tracking?
          metadata  = current.read
          start     = Time.parse( metadata.delete('start') )
          commit    = Muon::Commit.new(@project_dir, metadata, Time.now, start)
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

      def print_today_tracking(today_duration, today_percentage)
        puts "Today:    #{Muon::Format.duration(today_duration)} (#{today_percentage.to_i}%)."
      end

      def print_week_tracking(week_duration, week_percentage)
        puts "Week:     #{Muon::Format.duration(week_duration)} (#{week_percentage.to_i}%)."
      end

      def print_month_tracking(month_duration, month_percentage)
        puts "Month:    #{Muon::Format.duration(month_duration)} (#{month_percentage.to_i}%)."
      end
    end
  end
end
