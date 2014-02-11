Bundler.require(:default, ENV['RACK_ENV'])
require 'active_support/cache'
require 'active_support/core_ext/numeric/time'

Dotenv.load if defined?(Dotenv)

CITY = ENV['CITY']
STATE = ENV['STATE']
API_KEY = ENV['WUNDERGROUND_API_KEY']
ENDPOINT = 'http://api.wunderground.com/api/%s/conditions/q/%s/%s.json' % [API_KEY,STATE,CITY]

Connection = Faraday.new(url: ENDPOINT) do |conn|
  conn.response :caching do
    ActiveSupport::Cache::MemoryStore.new(expires_in: 300)
  end

  conn.response :json
  conn.response :logger

  conn.adapter Faraday.default_adapter
end

class Weather < Struct.new(:response)
  SNOW_INDICATOR = "snowing".freeze

  def snowing?
    response['current_observation']['weather'].downcase == SNOW_INDICATOR
  end

  def last_updated
    response['current_observation']['observation_time']
  end
end

get '/' do
  response = Connection.get.body
  @weather = Weather.new(response)
  erb :index
end
