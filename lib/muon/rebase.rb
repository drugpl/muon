module Muon
  class Rebase
    def initialize(project_dir, rebasing_branch)
      @project_dir     = project_dir
      @rebasing_branch = rebasing_branch
    end

    def call
      Dir.chdir(@project_dir) do
        branches = `ls .git/refs/heads`.split
        # current_branch = `git rev-parse --abbrev-ref HEAD`
        raise "Branch doesn't exist" if !branches.include?(@rebasing_branch)
        # below is a hack for one situation
        result = `git rebase #{@rebasing_branch}`
        unless result =~ /is up to date/
          puts `git checkout --theirs config`
          puts `git add config`
          puts `git rebase --continue`
        end
        # end of hack
        #
        # situation description:
        # create new muon repo
        # add config, commit
        # make some time entries
        # create new, completely empty (orphan) branch
        # create new config file with new attributes (branch, project for example)
        # try to use `muo rebase old-branch-name`
        # `config` file is 'in conflict' for git
        # so we want to force OUR version of this file
        # and rebase all of the rest
      end
    end
  end
end
