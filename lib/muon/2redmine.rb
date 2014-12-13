require 'fileutils'
require 'pathname'
require 'multi_json'
require 'uri'
require 'net/http'
require 'net/https'

require 'muon/report'
require 'muon/commit'
require 'muon/muon_path_finder'

module Muon
  class ToRedmine
    attr_reader :project_dir

    def initialize(project_dir)
      @project_dir = project_dir
    end

    def call
      project_dir = Muon::MuonPathFinder.new.call
      entries = Muon::Report.new(project_dir, nil, nil, nil, []).all_objects.sort_by{|e| e['start'] } # TODO: Extract
      config  = Muon::Commit.new(project_dir, nil, nil, nil).muon.config # TODO: Extract
      url = token = once = nil
      config.redmine_url ||= Proc.new do |entry|
        url ||= begin
          puts <<-NOTE
  \n\n
  Please set config.redmine_url in your .muon/config or answer the questions"
  Exemplary setting:
  config.redmine_url = Proc.new do |entry|
    # fdd741ff8ef1f81b348bf24f6be3cc90 is your Redmine API
    # access key from /my/account page on your Redmine
    "https://fdd741ff8ef1f81b348bf24f6be3cc90@redmine.example.org"
  end
  NOTE
          puts "\n\nWhat is your Redmine URL ? Example: https://redmine.example.org"
          gets.strip
        end

        token ||= begin
          puts "\n\nWhat is your Redmine API access key ? You can see it at: #{url}/my/account"
          gets.strip
        end

        print "\nSync #{entry['path']} ..." unless once
        once = true
        u = URI(url)
        u.user = token
        u.to_s
      end

      entries.each_with_index do |entry, index|
        next if entry['redmine_synced'] == true
        print "\nSync #{entry['path']} ..."
        entry_filename = entry['path']
        uri = URI( config.redmine_url.call(entry) )
        Net::HTTP.start(uri.host, uri.port) do |http|
          req = Net::HTTP::Post.new("/time_entries.json")
          req.basic_auth uri.user, uri.password
          req.add_field 'Content-Type', 'application/json'
          req.set_form_data({
            #TODO: Extract conversion into config method
            "time_entry[issue_id]" => issue = entry['ticket'],
            "time_entry[spent_on]" => entry['start'],
            "time_entry[hours]"    => entry['duration'] / 3600.0,
            "time_entry[activity_id]" => 8, #5
            "time_entry[comments]" => entry['comments'] || entry['description'],
          })
          result = http.request(req)
          if Net::HTTPCreated === result
            print "OK... "
            Dir.chdir(project_dir) do
              content = MultiJson.load(File.read(entry_filename))
              content['redmine_synced'] = true
              string  = MultiJson.dump(content, :pretty => true)
              File.open(entry_filename, "w") {|f| f.puts(string) }
              `git add #{entry_filename}`
              `git commit -m 'Synced #{issue} with #{uri.host}'`
              print "COMMITED"
            end
          else
            print "FAIL"
          end
        end
      end
    end
  end
end
