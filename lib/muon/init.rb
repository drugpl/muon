require 'fileutils'
require 'pathname'

module Muon
  class Init

    # command_dir ~/projects/projectA, init_dir = command_dir
    # command_dir ~/projects/projectA, init_dir = $HOME
    class Arguments < Struct.new(:command_dir, :init_dir, :project, :email, :branch)
      def initialize()
      end
    end

    class Error < StandardError; end
    class UnknownEmail < Error;  end

    attr_reader :project, :command_dir, :init_dir

    def initialize(arguments)
      @arguments    = arguments

      @command_dir  = arguments.command_dir or raise "Missing command dir"
      @init_dir     = arguments.init_dir || command_dir
      @email        = arguments.email
      @project      = arguments.project  || guess_project
      @branch       = arguments.branch

      @muon_dot    = Pathname.new(init_dir.to_s).join(".muon")
    end

    # http://stackoverflow.com/questions/9538328/git-root-branches-how-do-they-work
    def call
      #TODO: Make sure you cannot initialize twice
      FileUtils.mkdir_p(@muon_dot)
      Dir.chdir(@muon_dot) do
        puts `git init`
        puts `git symbolic-ref HEAD refs/heads/#{branch}`
        puts `rm -f .git/index`
        puts `git clean -fdx`
        puts `mkdir -p "tracking/" && touch "tracking/.gitkeep"`
        File.open("config", "w") {|config| config.puts(settings_content) }
        # TODO. .gitignore config file created ^^
        puts `git add tracking && git commit -m 'Muon tracking for #{email} initialized'`
      end

      #TODO: Register this project in muon list of known projects
    end

    private

    def settings_content
      ruby = <<-RUBY
        # config

        # Optional, Recommended
        config.email   = "#{email}"

        # Mandatory
        config.branch  = "#{branch}"

        # Optional, Recommended
        config.project = "#{project}"

        # Goals, optional:

        config.daily_hours      = Proc.new do |day|
          8
        end
        config.weekly_hours     = Proc.new do |beginning_of_week|
          40
        end
        config.monthly_hours    = Proc.new do |beginning_of_month|
          160
        end

        config.daily_revenue    = Proc.new do |day|
          0
        end
        config.weekly_revenue   = Proc.new do |beginning_of_week|
          0
        end
        config.monthly_revenue  = Proc.new do |beginning_of_month|
          0
        end

        # algorithm

        config.revenue_algorithm = Proc.new do |start, stop|
          per_hour = 0
          hours    = (stop - start) / 3600.0
          per_hour * hours
        end

        config.attributes = Proc.new do |start, stop|
          require 'socket'
          host = Socket.gethostname
          {
            email:    config.email,
            project:  config.project,
            hostname: host
          }
        end

        config.encrypted_attributes = Proc.new do |start, stop|
          {
            revenue: muon.revenue()
          }
        end

        config
      RUBY
    end

    def email
      @email || guess_email
    end

    #TODO: Extract go EmailGuesser
    def guess_email
      @guessed_email ||= begin
        e = `git config user.email`.strip
        # TODO: Guess based on hg and other possibile tools
        raise UnknownEmail, "Email could not be obtained via git settings" if e.empty?
        e
      end
    end

    def guess_project
      @command_dir.basename
    end

    def branch
      @branch || guess_branch
    end

    def guess_branch
      "muon-#{project}-#{email}"
    end
  end
end
