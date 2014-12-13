module Muon
  module Commands
    class Report
      def initialize(project_dir, global_options, options, args)
        @project_dir    = project_dir
        @global_options = global_options
        @options        = options
        @args           = args
      end

      def call
        all_branches = @options["all-branches"]

        period = :today
        period = :today if @options[:today]
        period = :week  if @options[:week]
        period = :month if @options[:month]

        group_by = []
        group_by << :day   if @options[:daily]
        group_by << :week  if @options[:weekly]
        group_by << :month if @options[:monthly]
        @options["group-by"].each do |group_by_entry|
          group_by << group_by_entry.to_sym
        end
        group_by.uniq!

        from, to = case period
          when :today then [ Time.now.beginning_of_day,   Time.now.end_of_day   ]
          when :week  then [ Time.now.beginning_of_week,  Time.now.end_of_week  ]
          when :month then [ Time.now.beginning_of_month, Time.now.end_of_month ]
          else raise "That's impossible."
        end

        result = Muon::Reporting.new(@project_dir, from, to, nil, group_by, all_branches).call
        table  = Muon::ReportTable.new(result, group_by).table
        puts Hirb::Helpers::AutoTable.render(table)
      end
    end
  end
end
