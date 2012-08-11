module Muon
  class Format
    def self.duration(seconds)
      seconds ||= 0
      seconds = seconds.to_i
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
