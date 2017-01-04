require 'sucker_punch'
require './define'
require './commands'

class CommandHandler
  include SuckerPunch::Job

  def perform(payload)
    command = /^\/(?<command>[\w\d]+)(?:|@RirushBot)(?:\s(?<args>.+))?$/ismu.match(payload['text'])
    return '' if command == nil
    args = ''
    begin
      args = command['args']
    rescue
      #
    end
    case command['command'].downcase
      when 'help'
        HelpCommand.perform_async(args, payload)
      when 'ping'
        PingCommand.perform_async(args, payload)
      when 'osu'
        OsuCommand.perform_async(args, payload)
      when 'users_dump'
        UsersDumpCommand.perform_async(args, payload)
      when 'chats_dump'
        ChatsDumpCommand.perform_async(args, payload)
      when 'get_chat'
        GetChatCommand.perform_async(args, payload)
      when 'broadcast'
        BroadcastCommand.perform_async(args, payload)
      when 'dice'
        DiceCommand.perform_async(args, payload)
      when 'echo'
        EchoCommand.perform_async(args, payload)
    end
  end
end