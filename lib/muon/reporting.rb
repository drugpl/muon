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
  class Reporting

    attr_reader :project_dir, :from, :to, :restrictions, :group_by

    def initialize(project_dir, from, to, restrictions, group_by, all_branches)
      @all_branches = all_branches
      @project_dir  = project_dir
      @from         = from
      @to           = to
      @group_by     = group_by.map(&:to_s)
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
          entry['duration'] ||= entry['stop'] - entry['start']
          entry['path'] = path.to_s

          objects << entry
        end
      end
      objects
    end

    def call
      objects = []
      if @all_branches
        Dir.chdir(project_dir) do
          branches = `ls .git/refs/heads`.split
          current_branch = `git rev-parse --abbrev-ref HEAD`.strip
          objects = branches.map do |branch|
            `git checkout #{branch}`
            all_objects
          end.flatten
          `git checkout #{current_branch}`
        end
      else
        objects = all_objects
      end
      types   = {}

      objects.each do |entry|
        entry.each do |key, value|
          types[key] ||= value.class
        end
      end

      group_by.each do |key|
        types[key] ||= String
      end

      types.delete("day")
      types.delete("week")
      types.delete("month")

      tuples = objects.map do |hash|
        ary = []
        types.keys.each do |k|
          ary << hash[k]
        end
        ary
      end

      relation = Veritas::Relation.new(types.to_a, tuples)
      relation = relation.extend do |r|
        r.add(:day)   {|t| t['start'].to_date }
        r.add(:week)  {|t| t['start'].beginning_of_week.strftime("W-%Y/%m/%d") }
        r.add(:month) {|t| t['start'].beginning_of_month.strftime("M-%Y/%m")   }
      end
      relation = relation.restrict { |r| r.start.gte from } if from
      relation = relation.restrict { |r| r.stop.lte to }    if to

      results  = []
      loop do
        summary = relation.summarize( relation.project(group_by) ) do |r|
          r.add(:sum, r.duration.sum)
        end.sort_by do |r|
          group_by.map{|g| r.send(g).asc } + [r.sum.asc]
        end
        results << summary
        break if group_by.size == 0
        group_by.pop
      end

      results
    end
  end
end
