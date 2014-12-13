module Muon
  class MuonPathFinder
    def call
      path = Pathname.new(Dir.pwd)
      while !muon_exists?(path)
        path = path.parent
        raise "No muon repository found" if path.root?
      end
      muonize_path(path)
    end

    def muon_exists?(path)
      Dir.exists?(muonize_path(path))
    end

    def muonize_path(path)
      path.join(".muon")
    end
  end
end
