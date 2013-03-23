require 'active_support/all'

module Muon
  class PerHour
    def initialize(working)
      @working = working
    end

    def compute
      per_hour = Range.new(0, 23).inject({}){|result, hour| result[hour] = 0; result}
      @working.each do |w|
        from  = w[:start]
        to    = w[:stop]

        start = from
        while start < to do
          nh   = start.beginning_of_hour + 3600
          stop = [nh, to].min
          diff = stop - start
          per_hour[start.hour] += diff
          start = nh
        end
      end

      per_hour
    end

  end
end
