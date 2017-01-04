require 'sinatra'
require 'faraday'
require 'json'
require 'sucker_punch'
require 'faraday-cookie_jar'
require 'faraday_middleware'
require 'redis'
require './command_handler'
require './beatmap_download'
require './define'
require './inline_handler'

$fd.post "/bot#{ENV['TOKEN']}/setWebhook", { :url => "https://rirushbot.herokuapp.com/hook/#{ENV['SECRETADDR']}/RirushBot/" }

before do
  request.body.rewind
  begin
    @request_payload = JSON.parse request.body.read
  rescue
    #
  end
end

post "/hook/#{ENV['SECRETADDR']}/RirushBot/" do
  puts @request_payload
  UserAdd.perform_async(@request_payload['message']['from']['id']) if @request_payload.has_key?('message')
  ChatAdd.perform_async(@request_payload['message']['chat']['id']) if @request_payload.has_key?('message')
  CommandHandler.perform_async(@request_payload['message']) if @request_payload.has_key?('message')
  InlineHandler.perform_async(@request_payload['inline_query'], @request_payload['query']) if @request_payload.has_key?('inline_query')
  'ok'
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