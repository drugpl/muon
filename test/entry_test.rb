require 'test_helper'
require 'muon/entry'

class Muon::EntryTest < Test::Unit::TestCase
  def test_from_commit
    commit = <<-EOF
tree 4b825dc642cb6eb9a060e54bf8d69288fbee4904
parent 49e6f4bd521ba93a7c99dd17e0a91b034a212165
author Jan Dudek <jd@jandudek.com> 1356453749 +0100
committer Jan Dudek <jd@jandudek.com> 1356453749 +0100

2012-12-25 15:00:00 +0100,2012-12-25 15:30:00 +0100
    EOF
    entry = Muon::Entry.from_commit(commit)
    assert_equal Time.parse('2012-12-25 15:00:00 +0100'), entry.start_time
    assert_equal Time.parse('2012-12-25 15:30:00 +0100'), entry.end_time
    assert_equal '49e6f4bd521ba93a7c99dd17e0a91b034a212165', entry.parent_hash
  end

  def test_from_commit_without_parent
    commit = <<-EOF
tree 4b825dc642cb6eb9a060e54bf8d69288fbee4904
author Jan Dudek <jd@jandudek.com> 1356453749 +0100
committer Jan Dudek <jd@jandudek.com> 1356453749 +0100

2012-12-25 15:00:00 +0100,2012-12-25 15:30:00 +0100
    EOF
    entry = Muon::Entry.from_commit(commit)
    assert_equal Time.parse('2012-12-25 15:00:00 +0100'), entry.start_time
    assert_equal Time.parse('2012-12-25 15:30:00 +0100'), entry.end_time
    assert_nil entry.parent_hash
  end
end
