require "digest/sha1"
require "muon/entry"

module Muon
  class History
    def initialize(working_dir)
      @working_dir = working_dir
    end

    def entries
      if block_given?
        entry = load_entry(head)
        while entry
          yield entry
          entry = load_entry(entry.parent_hash)
        end
      else
        enum_for :entries
      end
    end

    def append(entry)
      self.head = save_entry(entry.with_parent_hash(head))
    end

    private

    attr_reader :working_dir

    def head
      rev = run "git rev-parse --verify --quiet refs/muon/master"
      return rev.strip if rev != ""
    end

    def head=(hash)
      run "git update-ref refs/muon/master #{hash}"
    end

    def load_entry(hash)
      return nil if hash.nil?
      Entry.from_commit(run "git cat-file -p #{hash}")
    end

    def save_entry(entry)
      tree = run "cat /dev/null | git mktree"
      hash = run "git commit-tree #{'-p ' + entry.parent_hash if entry.parent_hash} -m '#{entry.start_time},#{entry.end_time}' #{tree}"
      return hash.strip
    end

    def run(cmd)
      ENV['GIT_DIR'] = working_dir
      `#{cmd}`
    end
  end
end
