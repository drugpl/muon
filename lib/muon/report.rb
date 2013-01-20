require 'fileutils'
require 'pathname'
require 'veritas'
require 'active_support/all'
require 'multi_json'
require 'pathname'

# muon report --from=yesterday --to=tomorrow --where=r.project.eq('Project1') --daily --group-by=email --group-by=ticket --key=value
# remember to yourself.
# you are not building reporting engine
# anyone can do it using Ruby/Veritas himself if needs something complicated
#
# by default chcialbym tylko z tego projektu i z tego brancha
# --all-branches to wszystkie branche muon-*
# branches= pozwala wybrac inne
#
# --all-projects
# projects=/p1:/p2
#
# --global = --all-branches && --all-projects
#
# Na poczatek potrzebuje tylko z tego brancha tego projektu
# i ja zawsze chce zrobic jakies summary (sumę), jak nie ma zadnego podanego
# to
#
#new_relation = relation.summarize() { |r| r.add(:sum, r.weight.sum) }
# a jak sa to:
#new_relation = relation.summarize(relation.project([ :city ])) { |r| r.add(:sum, r.weight.sum) }
# a jak kilka:
#new_relation = relation.summarize(relation.project([ :city, :color ])) { |r| r.add(:sum, r.weight.sum) }

module Muon
  class Report

    attr_reader :project_dir, :from, :to, :restrictions, :group_by

    # from/to are restrictions which can be often and easily applied to and might have special meanings
    # group_by are summaries which might have special meaning such as
    #  * daily
    #  * weekly
    #  * monthly
    def initialize(project_dir, from, to, restrictions, group_by)
      @project_dir  = project_dir
      @from         = from
      @to           = to
      @group_by     = group_by.clone
    end

    def call
      objects = []
      types   = {}
      Dir.chdir(project_dir) do
        Dir.glob("tracking/**/*") do |path|
          path  = Pathname.new(path)
          next  if path.directory?
          json  = Pathname.new(path).read

          entry = MultiJson.load(json)
          entry['start'] = Time.parse(entry['start']) if entry['start']
          entry['stop']  = Time.parse(entry['stop'])  if entry['stop']
          entry['duration'] ||= entry['stop'] - entry['start']

          objects << entry
        end
      end

      objects.each do |entry|
        entry.each do |key, value|
          types[key] ||= value.class
        end
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
      relation = relation.extend { |r| r.add(:day)   {|t| t['start'].to_date } }
      relation = relation.extend { |r| r.add(:week)  {|t| t['start'].beginning_of_week.strftime("W-%Y/%m/%d") } }
      relation = relation.extend { |r| r.add(:month) {|t| t['start'].beginning_of_month.strftime("M-%Y/%m")   } }

      loop do
        results << relation.summarize( relation.project(group_by) ) { |r| r.add(:sum, r.duration.sum) }
        break if group_by.size == 0
        group_by.pop
      end

      results
    end
  end
end
