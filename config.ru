require 'opal'
require 'opal-jquery'
require 'sinatra/base'
require 'sinatra/reloader'

opal = Opal::Server.new do |s|
  s.append_path 'app'
  s.append_path 'vendor'
  s.main = 'application'
end

sprockets   = opal.sprockets
prefix      = '/assets'
maps_prefix = '/__OPAL_SOURCE_MAPS__'
maps_app    = Opal::SourceMapServer.new(sprockets, maps_prefix)

# Monkeypatch sourcemap header support into sprockets
::Opal::Sprockets::SourceMapHeaderPatch.inject!(maps_prefix)

map maps_prefix do
  run maps_app
end

map prefix do
  run sprockets
end

app = Sinatra.new do
  configure do
    set :sprockets, sprockets
    set :prefix, prefix
  end
  configure :development do
    register Sinatra::Reloader
  end

  get '/' do
    @title = '計算機'
    erb :calc, layout: :layout
  end
end

run app
