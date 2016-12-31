require 'sinatra'
require 'faraday'
require 'json'

fd = Faraday.new(:url => "https://api.telegram.org") do |faraday|
  faraday.request     :url_encoded
  faraday.response    :logger
  faraday.adapter     Faraday.default_adapter
end

fd.get "/bot#{ENV['TOKEN']}/setWebhook", { :url => "https://rirushbot.herokuapp.com/hook/#{ENV['SECRETADDR']}/RirushBot/" }

before do
  request.body.rewind
  @request_payload = JSON.parse request.body.read
end
post "/hook/#{ENV['SECRETADDR']}/RirushBot/" do
  puts @request_payload
  "ok"
end