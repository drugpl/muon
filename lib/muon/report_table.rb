module Muon
  class ReportTable
    attr_reader :result, :groups

    def initialize(result, groups)
      @result = result
      @groups = groups
    end

    def table
      lines    = []
      blah     = result.clone
      relation = blah.shift
      headers  = groups.map {|g| relation[g] }
      all      = headers + [ relation[:sum] ]

      relation.each do |tuple|
        line = tuple.project(all).to_ary
        lines << line
      end

      loop do
        headers.pop
        relation = blah.shift
        break unless headers.present?
        relation.each do |tuple|
          found = nil
          new   = tuple.project(all).to_ary
          lines.each_with_index do |line, index|
            if line.first(headers.size) == new.first(headers.size)
              found = index
            end
          end

          lines.insert(found + 1, new)
        end

      end

      result.last.each{|t| lines << t.project(all).to_ary}
      lines
    end
  end
end
