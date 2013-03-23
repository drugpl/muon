require 'muon/version'

module Muon
  def self.root
    require 'pathname'
    Pathname.new(File.expand_path('../', File.dirname(__FILE__)))
  end
end
