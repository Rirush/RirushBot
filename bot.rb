require 'sinatra'
require 'faraday'
require 'json'
require 'sucker_punch'
require 'faraday-cookie_jar'

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

fd.post "/bot#{ENV['TOKEN']}/setWebhook", { :url => "https://rirushbot.herokuapp.com/hook/#{ENV['SECRETADDR']}/RirushBot/" }

before do
  request.body.rewind
  @request_payload = JSON.parse request.body.read
end

post "/hook/#{ENV['SECRETADDR']}/RirushBot/" do
  puts @request_payload
  if (/^\/ping*/ =~ @request_payload['message']['text']) != nil then
    fd.post "/bot#{ENV['TOKEN']}/sendMessage", {
        :chat_id => @request_payload['message']['from']['id'],
        :text => "Pong!",
        :reply_to_message_id => @request_payload['message']['message_id']
    }
  end
  if (/\/osu http[s]:\/\/osu.ppy.sh\/s\/(?<id>\d+)/ =~ @request_payload['message']['text']) != nil then
    BeatmapDownload.perform_async /\/osu http[|s]:\/\/osu.ppy.sh\/s\/(?<id>\d+)/.match(@request_payload['message']['text'])[:id], @request_payload['message']['chat']['id'], @request_payload['message']['message_id']
    fd.post "/bot#{ENV['TOKEN']}/sendMessage", {
        :chat_id => @request_payload['message']['chat']['id'],
        :text => "Your beatmap going to be downloaded soon",
        :reply_to_message_id => @request_payload['message']['message_id']
    }
  end
  "ok"
end

class BeatmapDownload
  include SuckerPunch::Job

  def perform(beatmapid, userid, messageid)
    osu = Faraday.new(:url => "https://osu.ppy.sh") do |faraday|
      faraday.use      :cookie_jar
      faraday.request  :url_encoded
      faraday.response :logger
      faraday.adapter  Faraday.default_adapter
    end
    fd = Faraday.new(:url => "https://api.telegram.org") do |faraday|
      faraday.request  :url_encoded
      faraday.response :logger
      faraday.adapter  Faraday.default_adapter
    end
    osu.post "/forum/ucp.php?mode=login", { form: { username: ENV['OSULOGIN'], password: ENV['OSUPASS'], autologin: 'on', sid: '', login: 'login' } }
    beatmap = osu.get "/d/#{beatmapid}n"
    puts beatmap.body
    fd.post "/bot#{ENV['TOKEN']}/sendDocument", {
        :chat_id => userid,
        :text => "Your beatmap was succesfully downloaded! BeatmapID = #{beatmapid}",
        :reply_to_message_id => messageid,
        :document => beatmap.body
    }
  end
end