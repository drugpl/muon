require 'fileutils'
require 'pathname'
require 'veritas'
require 'active_support/all'
require 'multi_json'
require 'pathname'

# group by
#  --daily
#  --weekly
#  --monthly
#  --group-by=day,email,ticket
#  or
#  --group-by=email --group-by=ticket
#
# restrict
#  muon report --today
#  muon report --day
#  muon report --week
#  muon report --month
#
# muon report --from=yesterday --to=tomorrow --where=project.eq('Project1') --daily --group-by=email,ticket key=value
#
# you are not building reporting engine
# anyone can do it using Ruby/Veritas himself if needs something complicated
#
# by default chcialbym tylko z tego projektu i z tego brancha
# --all-branches to wszystkie branche muon-*
# branches= pozwala wybrac inne
#
# --all-projects
# projects=/p1,/p2
#
# --global = --all-branches && --all-projects
#
# Na poczatek potrzebuje tylko z tego brancha tego projektu

# https://github.com/dkubb/veritas/issues/26
Veritas::Relation::Operation::Order::Ascending.class_eval do
  def self.call(left, right)
    left <=> right || (-1 if right.nil?) || (1 if left.nil?)
  end
end
Veritas::Relation::Operation::Order::Descending.class_eval do
  def self.call(left, right)
    left, right = right, left
    left <=> right || (-1 if right.nil?) || (1 if left.nil?)
  end
end

module Muon
  class Report

    attr_reader :project_dir, :from, :to, :restrictions, :group_by

    # from/to are restrictions which can be often and easily applied to and might have special meanings
    # group_by are summaries which might have special meaning such as
    #  * daily
    #  * weekly
    #  * monthly
    def initialize(project_dir, from, to, restrictions, group_by)
      group_by      = group_by.map(&:to_s)
      @project_dir  = project_dir
      @from         = from
      @to           = to
      @group_by     = group_by.clone
      @group_by2    = group_by.clone
    end

    def all_objects
      objects = []
      Dir.chdir(project_dir) do
        Dir.glob("tracking/**/*") do |path|
          path  = Pathname.new(path)
          next  if path.directory?
          json  = Pathname.new(path).read

          entry = MultiJson.load(json)
          entry['start'] = Time.parse(entry['start']) if entry['start']
          entry['stop']  = Time.parse(entry['stop'])  if entry['stop']
          entry['duration'] ||= (entry['stop'] - entry['start']) / 3600.0
          entry['path'] = path.to_s
          #entry['duration'] = entry['duration'] / 3600.0

          objects << entry
        end
      end
      objects
    end

    def call
      objects = all_objects
      types   = {}

      objects.each do |entry|
        entry.each do |key, value|
          types[key] ||= value.class
        end
      end

      group_by.each do |key|
        types[key] ||= String
      end

      tuples   = objects.map do |hash|
        ary = []
        types.keys.each do |k|
          ary << hash[k]
        end
        ary
      end

      results  = []
      relation = Veritas::Relation.new(types.to_a, tuples)
      relation = relation.extend   { |r| r.add(:day)   {|t| t['start'].to_date } }
      relation = relation.extend   { |r| r.add(:week)  {|t| t['start'].beginning_of_week.strftime("W-%Y/%m/%d") } }
      relation = relation.extend   { |r| r.add(:month) {|t| t['start'].beginning_of_month.strftime("M-%Y/%m")   } }
      relation = relation.restrict { |r| r.start.gte from } if from
      relation = relation.restrict { |r| r.stop.lte to }    if to

      loop do
        results << relation.summarize( relation.project(group_by) ) { |r| r.add(:sum, r.duration.sum) }.sort_by do |r|
          group_by.map{|g| r.send(g).asc } + [r.sum.asc]
        end
        break if group_by.size == 0
        group_by.pop
      end

      results
    end
  end
end
