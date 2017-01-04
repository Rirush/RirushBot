require 'faraday'
require 'redis'

$fd = Faraday.new(:url => "https://api.telegram.org") do |faraday|
  faraday.request  :multipart
  faraday.request  :url_encoded
  faraday.response :logger
  faraday.adapter  Faraday.default_adapter
end

$osu = Faraday.new(:url => "https://osu.ppy.sh") do |faraday|
  faraday.use      FaradayMiddleware::FollowRedirects
  faraday.use      :cookie_jar
  faraday.request  :url_encoded
  faraday.response :logger
  faraday.adapter  Faraday.default_adapter
end

$upload = Faraday.new(:url => "https://desu.sh") do |faraday|
  faraday.request  :multipart
  faraday.request  :url_encoded
  faraday.response :logger
  faraday.adapter  Faraday.default_adapter
end

$redis = Redis.new(url: ENV['REDIS_URL'])

$help = "Nobody gonna help you in this world. But I can give you commandlist.

/osu <beatmap_link> - download Osu! beatmap and send it in chat
/dice <range> - get random number in given range
/echo <text> - say text given as a arg
/help - show this useless message

More features upcoming!"