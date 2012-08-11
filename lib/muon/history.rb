require "digest/sha1"

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

    def head_file
      File.join(@working_dir, "HEAD")
    end

    def head
      @head ||= if File.exists?(head_file)
        File.read(head_file).strip
      else
        nil
      end
    end

    def head=(hash)
      @head = hash
      File.open(head_file, "w") { |f| f.write(hash + "\n") }
    end

    def load_entry(hash)
      return nil if hash.nil?
      File.open(file_for_hash(hash), "r") { |f| Entry.from_s(f.read) }
    end

    def save_entry(entry)
      contents = entry.to_s
      hash = compute_hash(contents)
      File.open(file_for_hash(hash), "w") { |f| f.write(contents) }
      return hash
    end

    def file_for_hash(hash)
      File.join(@working_dir, "objects", hash)
    end

    def verify_hash(contents, hash)
      raise "Hash #{hash} does not match contents!" if compute_hash(compute_hash) != hash
    end

    def compute_hash(contents)
      Digest::SHA1.hexdigest(contents)
    end
  end
end
