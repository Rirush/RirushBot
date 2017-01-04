require 'sucker_punch'
require './define'

class EventLogger
  include SuckerPunch::Job

  def perform(payload)
    puts 'Incoming message' if payload.has_key?('message')
    puts 'Incoming inline query' if payload.has_key?('inline_query')
    puts "Message from #{payload['message']['from']['username']} / #{payload['message']['from']['id']}" if payload.has_key?('message')
    puts "Message: #{payload['message']['text']}" if payload.has_key?('message')
    puts "Query: #{payload['inline_query']['query']}" if payload.has_key?('inline_query')
    puts "Payload:\n#{payload}"
  end
end