require './define'
require './beatmap_download'
require './commands'
require 'sucker_punch'

# Class for handling inline updates
class InlineHandler
  include SuckerPunch::Job

  def perform(querydata, querytext)
    osu = /http(?:|s):\/\/osu.ppy.sh\/(s|d)\/(?<id>\d+)/i.match(querytext)
    BeatmapDownload.perform_async(osu['id'], querydata['id'], -1, true) if osu != nil
    inline_regex = /^(?<cmd>[a-zA-Z_]+)(?<args>.*)/iu
    info = inline_regex.match(querytext)
    return '' unless info
    payload = querydata
    args = info['args'].sub! ' ', ''
    case info['cmd']
      when 'help'
        HelpCommand.perform_async(args, payload, true)
      when 'ping'
        PingCommand.perform_async(args, payload, true)
      when 'users_dump'
        UsersDumpCommand.perform_async(args, payload, true)
      when 'chats_dump'
        ChatsDumpCommand.perform_async(args, payload, true)
      when 'get_chat'
        GetChatCommand.perform_async(args, payload, true)
      #when 'dice'
      #  DiceCommand.perform_async(args, payload, true)
      when 'echo'
        EchoCommand.perform_async(args, payload, true)
    end
  end
end
