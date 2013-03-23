require 'muon/report'
require 'sinatra/base'

app = Sinatra.new do
  enable :static
  set :public_folder, Muon.root.join("www/public")
  set :views, Muon.root.join("www/views")
  get('/') do
    erb :index, layout: true
  end
end
app.run!
