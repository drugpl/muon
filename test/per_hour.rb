require 'test_helper'
require 'muon/per_hour'

module Muon
  class PerHourTest < Test::Unit::TestCase
    def test_computes_minutes_of_work_for_hours
      working = [{
        start: Time.new(2013, 3, 1, 23, 40),
        stop:   Time.new(2013, 3, 2, 1, 20)
      }, {
        start: Time.new(2013, 3, 2, 1, 30),
        stop:   Time.new(2013, 3, 2, 1, 40)
      }, {
        start: Time.new(2013, 3, 2, 2, 00),
        stop:   Time.new(2013, 3, 2, 3, 00)
      }, {
        start: Time.new(2013, 3, 2, 3, 15),
        stop:   Time.new(2013, 3, 2, 5, 15, 1)
      },
      ]

      result = PerHour.new(working).compute
      assert_equal({
        0 => (60)*60,
        1 => (20 + 10)*60,
        2 => (60)*60,
        3 => (45)*60,
        4 => (60)*60,
        5 => (15)*60 + 1,
        6 => 0,
        7 => 0,
        8 => 0,
        9 => 0,
        10 => 0,
        11 => 0,
        12 => 0,
        13 => 0,
        14 => 0,
        15 => 0,
        16 => 0,
        17 => 0,
        18 => 0,
        19 => 0,
        20 => 0,
        21 => 0,
        22 => 0,
        23 => (20)*60,
      }, result)
    end
  end
end

