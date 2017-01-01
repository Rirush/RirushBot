require 'sucker_punch'
require './define'
require './beatmap_download'
require 'json'

class HelpCommand
  include SuckerPunch::Job

  def perform(args, payload)
    $fd.post "/sendMessage", {
        :chat_id => payload['chat']['id'],
        :text => $help,
        :reply_to_message_id => payload['message_id']
    }
  end
end

class PingCommand
  include SuckerPunch::Job

  def perform(args, payload)
    $fd.post "/sendMessage", {
        :chat_id => payload['chat']['id'],
        :text => 'Got ping. PONG!',
        :reply_to_message_id => payload['message_id']
    }
  end
end

class OsuCommand
  include SuckerPunch::Job

  def perform(args, payload)
    BeatmapDownload(/http(?:|s):\/\/osu.ppy.sh\/s\/(?<id>\d+)/i.match(args)[:id], payload['chat']['id'], payload['message_id']) if /http(?:|s):\/\/osu.ppy.sh\/s\/(?<id>\d+)/i.match(args)
  end
end

class UsersDumpCommand
  include SuckerPunch::Job

  def perform(args, payload)
    if payload['from']['id'] == 125836701
      users = JSON.parse $redis.get('users')
      $fd.post '/sendMessage', {
          :chat_id => payload['chat']['id'],
          :text => users,
          :reply_to_message_id => payload['message_id']
      }
    end
  end
end

class ChatsDumpCommand
  include SuckerPunch::Job

  def perform(args, payload)
    if payload['from']['id'] == 125836701
      chats = JSON.parse $redis.get('chats')
      $fd.post '/sendMessage', {
          :chat_id => payload['chat']['id'],
          :text => chats,
          :reply_to_message_id => payload['message_id']
      }
    end
  end
end

class GetChatCommand
  include SuckerPunch::Job

  def perform(args, payload)
    if payload['from']['id'] == 125836701
      chat = $fd.post '/getChat', {
          :chat_id => args
      } if /-\d+/i.match(args)
      $fd.post '/sendMessage', {
          :chat_id => payload['chat']['id'],
          :text => chat.body,
          :reply_to_message_id => payload['message_id']
      }
    end
  end
end

class BroadcastCommand
  include SuckerPunch::Job

  def perform(args, payload)
    if payload['from']['id'] == 125836701
      chats = $redis.get('chats')
      for chat in chats
        $fd.post '/sendMessage', {
            :chat_id => chat,
            :text => args
        } if args != ''
      end
      $fd.post '/sendMessage', {
          :chat_id => payload['chat']['id'],
          :text => 'Broadcasted!',
          :reply_to_message_id => payload['message_id']
      }
    end
  end
end

class DiceCommand
  include SuckerPunch::Job

  def perform(args, payload)
    range = Integer(/(?:|-)\d+/i.match(args))
    if range > 1
      result = rand(range + 1)
      $fd.post '/sendMessage', {
          :chat_id => payload['chat']['id'],
          :text => "*Dice* says: _#{result}_",
          :parse_mode => 'Markdown',
          :reply_to_message_id => payload['message_id']
      }
    else
      $fd.post '/sendMessage', {
          :chat_id => payload['chat']['id'],
          :text => '*Dice* says: _fuck you_',
          :parse_mode => 'Markdown',
          :reply_to_message_id => payload['message_id']
      }
    end
  end
end

class EchoCommand
  include SuckerPunch::Job

  def perform(args, payload)
    $fd.post '/sendMessage', {
        :chat_id => payload['chat']['id'],
        :text => "*Bot* says: _#{args}_",
        :parse_mode => 'Markdown',
        :reply_to_message_id => payload['message_id']
    } if args != ''
  end
end