require 'sinatra'
require 'faraday'
require 'json'
require 'sucker_punch'

fd = Faraday.new(:url => "https://api.telegram.org") do |faraday|
  faraday.request     :url_encoded
  faraday.response    :logger
  faraday.adapter     Faraday.default_adapter
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
  if (/\/osu http[s]:\/\/osu.ppy.sh\/s\/(?<id>\d*)/ =~ @request_payload['message']['text']) != nil then
    BeatmapDownload.perform_async /\/osu http[s]:\/\/osu.ppy.sh\/s\/(?<id>\d*)/.match(@request_payload['message']['text'])[:id]
    fd.post "/bot#{ENV['TOKEN']}/sendMessage", {
        :chat_id => @request_payload['message']['from']['id'],
        :text => "Your beatmap going to be downloaded soon",
        :reply_to_message_id => @request_payload['message']['message_id']
    }
  end
  "ok"
end

class BeatmapDownload
  include SuckerPunch::Job

  def perform(data)
    puts data
  end
end