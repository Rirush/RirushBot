require 'sinatra'
require 'faraday'
require 'json'
require 'sucker_punch'
require 'faraday-cookie_jar'
require 'faraday_middleware'
require 'redis'

fd = Faraday.new(:url => "https://api.telegram.org") do |faraday|
  faraday.request  :url_encoded
  faraday.response :logger
  faraday.adapter  Faraday.default_adapter
end

osu = Faraday.new(:url => "https://osu.ppy.sh") do |faraday|
  faraday.request  :url_encoded
  faraday.response :logger
  faraday.adapter  Faraday.default_adapter
  faraday.use      :cookie_jar
end

$redis = Redis.new(url: ENV['REDIS_URL'])

fd.post "/bot#{ENV['TOKEN']}/setWebhook", { :url => "https://rirushbot.herokuapp.com/hook/#{ENV['SECRETADDR']}/RirushBot/" }

before do
  request.body.rewind
  begin
    @request_payload = JSON.parse request.body.read
  rescue
    #
  end
end

get "/" do
  "<h1>Heroku app is up!</h1>"
end
post "/" do
  "<h1>Heroku app is up!</h1>"
end
post "/hook/#{ENV['SECRETADDR']}/RirushBot/" do
  puts @request_payload
  return 'ok' unless @request_payload.has_key?('message')
  UserAdd.perform_async(@request_payload['message']['from']['id'])
  ChatAdd.perform_async(@request_payload['message']['chat']['id'])
  if (/^\/ping(|@RirushBot)/i =~ @request_payload['message']['text']) != nil then
    fd.post "/bot#{ENV['TOKEN']}/sendMessage", {
        :chat_id => @request_payload['message']['chat']['id'],
        :text => "Pong!",
        :reply_to_message_id => @request_payload['message']['message_id']
    }
  end
  if (/^\/osu http[s]:\/\/osu.ppy.sh\/s\/(?<id>\d+)/i =~ @request_payload['message']['text']) != nil then
    BeatmapDownload.perform_async /\/osu http[|s]:\/\/osu.ppy.sh\/s\/(?<id>\d+)/.match(@request_payload['message']['text'])[:id], @request_payload['message']['chat']['id'], @request_payload['message']['message_id']
    fd.post "/bot#{ENV['TOKEN']}/sendMessage", {
        :chat_id => @request_payload['message']['chat']['id'],
        :text => "Your beatmap going to be downloaded soon",
        :reply_to_message_id => @request_payload['message']['message_id']
    }
  end
  if (/^\/users_dump(|@RirushBot)/i =~ @request_payload['message']['text']) != nil then
    if @request_payload['message']['from']['id'] == 125836701 then
      users = $redis.get('users')
      fd.post "/bot#{ENV['TOKEN']}/sendMessage", {
          :chat_id => @request_payload['message']['chat']['id'],
          :text => users,
          :reply_to_message_id => @request_payload['message']['message_id']
      }
    end
  end
  if (/^\/chats_dump(|@RirushBot)/i =~ @request_payload['message']['text']) != nil then
    if @request_payload['message']['from']['id'] == 125836701 then
      chats = $redis.get('chats')
      fd.post "/bot#{ENV['TOKEN']}/sendMessage", {
          :chat_id => @request_payload['message']['chat']['id'],
          :text => chats,
          :reply_to_message_id => @request_payload['message']['message_id']
      }
    end
  end
  if (/^\/getChat(|@RirushBot) (?<chatid>(|-)\d+)/i =~ @request_payload['message']['text']) != nil then
    if @request_payload['message']['from']['id'] == 125836701 then
      regex = /^\/getChat(|@RirushBot) (?<chatid>(|-)\d+)/i.match(@request_payload['message']['text'])
      chat = regex[:chatid]
      res = fd.post "/bot#{ENV['TOKEN']}/getChat", {
          :chat_id => chat
      }
      fd.post "/bot#{ENV['TOKEN']}/sendMessage", {
          :chat_id => @request_payload['message']['chat']['id'],
          :text => res.body,
          :reply_to_message_id => @request_payload['message']['message_id']
      }
    end
  end
  "ok"
end

# загрузка битмап осу
class BeatmapDownload
  include SuckerPunch::Job

  def get_beatmap_info(beatmapid)
    osu = Faraday.new(:url => "https://osu.ppy.sh") do |faraday|
      faraday.use      FaradayMiddleware::FollowRedirects
      faraday.use      :cookie_jar
      faraday.request  :url_encoded
      faraday.response :logger
      faraday.adapter  Faraday.default_adapter
    end
    info = osu.post "/api/get_beatmaps", { k: ENV['OSUTOKEN'], s: beatmapid, limit: 1 }
    name = JSON.parse info.body
    name[0]
  end

  def perform(beatmapid, userid, messageid)
    osu = Faraday.new(:url => "https://osu.ppy.sh") do |faraday|
      faraday.use      FaradayMiddleware::FollowRedirects
      faraday.use      :cookie_jar
      faraday.request  :url_encoded
      faraday.response :logger
      faraday.adapter  Faraday.default_adapter
    end
    fd = Faraday.new(:url => "https://api.telegram.org") do |faraday|
      faraday.request  :multipart
      faraday.response :logger
      faraday.adapter  Faraday.default_adapter
    end

    osu.post "/forum/ucp.php?mode=login", { username: ENV['OSULOGIN'], password: ENV['OSUPASS'], autologin: 'on', sid: '', login: 'login' }
    beatmap = osu.get "/d/#{beatmapid}n"
    beatmapdata = get_beatmap_info(beatmapid)
    filename = "#{beatmapdata['creator']}: #{beatmapdata['artist']} - #{beatmapdata['title']}"
    io = UploadIO.new(StringIO.new(beatmap.body), beatmap.headers[:content_type], "#{filename}.osz")
    fd.post "/bot#{ENV['TOKEN']}/sendDocument", {
        :chat_id => userid,
        :caption => "Your beatmap was succesfully downloaded! BeatmapID = #{beatmapid}",
        :reply_to_message_id => messageid,
        :document => io
    }
  end
end

# добавление юзера в бд
class UserAdd
  include SuckerPunch::Job

  def perform(userid)
    users = $redis.get('users')
    begin
      users = JSON.parse users
    rescue
      $redis.set('users', [].to_json)
      users = []
    end
    users << userid unless users.include?(userid)
    $redis.set('users', users.to_json)
  end
end

# добавление чата в бд
class ChatAdd
  include SuckerPunch::Job

  def perform(chatid)
    chats = $redis.get('chats')
    begin
      chats = JSON.parse chats
    rescue
      $redis.set('chats', [].to_json)
      chats = []
    end
    chats << chatid unless chats.include?(chatid)
    $redis.set('chats', chats.to_json)
  end
end