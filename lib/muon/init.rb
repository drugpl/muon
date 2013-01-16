require 'fileutils'
require 'pathname'

module Muon
  class Init
    class Error < StandardError; end
    class UnknownEmail < Error;  end
    EMPTY_EMAIL = Object.new

    # command_dir ~/projects/projectA, init_dir = command_dir
    # command_dir ~/projects/projectA, init_dir = $HOME
    def initialize(command_dir = Dir.pwd, init_dir = command_dir, email = EMPTY_EMAIL)
      @command_dir = command_dir
      @init_dir    = init_dir
      @muon_dot    = Pathname.new(init_dir.to_s).join(".muon")
      @email       = email
    end

    # http://stackoverflow.com/questions/9538328/git-root-branches-how-do-they-work
    def call
      #TODO: Make sure you cannot initialize twice
      FileUtils.mkdir_p(@muon_dot)
      Dir.chdir(@muon_dot) do
        puts `git init`
        puts `git symbolic-ref HEAD refs/heads/#{email}`
        puts `rm -f .git/index`
        puts `git clean -fdx`
        puts `mkdir tracking && touch tracking/.gitkeep`
        puts `git add tracking && git commit -m 'Muon tracking for #{email} initialized'`
      end
    end

    def email
      if EMPTY_EMAIL
        guess_email
      else
        @email
      end
    end

    #TODO: Extract go EmailGuesser
    def guess_email
      @guessed_email ||= begin
        e = `git config user.email`
        # TODO: Guess based on hg and other possibile tools
        raise UnknownEmail, "Email could not be obtained via git settings" if e.strip.empty?
        e
      end
    end
  end
end
