require 'sucker_punch'
require './define'

class EventLogger
  include SuckerPunch::Job

  def perform(payload)
    puts 'Incoming message' if payload.has_key?('message')
    mainkey = 'message' if payload.has_key?('message')
    puts 'Incoming inline query' if payload.has_key?('inline_query')
    mainkey = 'inline_query' if payload.has_key?('inline_query')
    puts "Message from #{payload['mainkey']['from']['username']} / #{payload['mainkey']['from']['id']}" if payload.has_key?('message')
    puts "Message: #{payload['mainkey']['text']}" if payload.has_key?('message')
    puts "Query: #{payload['inline_query']['query']}" if payload.has_key?('inline_query')
    puts "\n\nPayload:\n#{payload}"
  end
end