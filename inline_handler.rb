require './define'
require './beatmap_download'
require './commands'
require 'sucker_punch'

class InlineHandler
  include SuckerPunch::Job

  def perform(querydata, querytext)
    osu = /http(?:|s):\/\/osu.ppy.sh\/s\/(?<id>\d+)/i.match(querytext)
    BeatmapDownload.perform_async(osu['id'], querydata['id'], -1, true) if osu != nil
    inline_regex = /^(?<cmd>[a-zA-Z_]+)(?<args>.*)/iu
    info = inline_regex.match(querytext)
    payload = querydata
    args = info['args'].sub! ' ', ''
    case info['cmd']
      when 'help'
        HelpCommand.perform_async(args, payload, true)
      when 'ping'
        PingCommand.perform_async(args, payload, true)
      when 'osu'
        OsuCommand.perform_async(args, payload, true)
      when 'users_dump'
        UsersDumpCommand.perform_async(args, payload, true)
      when 'chats_dump'
        ChatsDumpCommand.perform_async(args, payload, true)
      when 'get_chat'
        GetChatCommand.perform_async(args, payload, true)
      when 'broadcast'
        BroadcastCommand.perform_async(args, payload, true)
      when 'dice'
        DiceCommand.perform_async(args, payload, true)
      when 'echo'
        EchoCommand.perform_async(args, payload, true)
    end
  end
end