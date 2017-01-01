require 'sucker_punch'
require './define'

class BeatmapDownload
  include SuckerPunch::Job

  def get_beatmap_info(beatmapid)
    info = $osu.post "/api/get_beatmaps", { k: ENV['OSUTOKEN'], s: beatmapid, limit: 1 }
    name = JSON.parse info.body
    name[0]
  end

  def perform(beatmapid, userid, messageid)

    $osu.post "/forum/ucp.php?mode=login", { username: ENV['OSULOGIN'], password: ENV['OSUPASS'], autologin: 'on', sid: '', login: 'login' }
    beatmap = $osu.get "/d/#{beatmapid}n"
    beatmapdata = get_beatmap_info(beatmapid)
    filename = "#{beatmapdata['artist']} - #{beatmapdata['title']}"
    io = UploadIO.new(StringIO.new(beatmap.body), beatmap.headers[:content_type], "#{filename}.osz")
    $fd.post "/bot#{ENV['TOKEN']}/sendDocument", {
        :chat_id => userid,
        :caption => "Your beatmap was succesfully downloaded! BeatmapID = #{beatmapid}",
        :reply_to_message_id => messageid,
        :document => io
    }
  end
end