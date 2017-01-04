require 'sucker_punch'
require './define'
require 'json'

class BeatmapDownload
  include SuckerPunch::Job

  def get_beatmap_info(beatmapid)
    info = $osu.post "/api/get_beatmaps", { k: ENV['OSUTOKEN'], s: beatmapid, limit: 1 }
    name = JSON.parse info.body
    name[0]
  end

  def perform(beatmapid, userid, messageid, mode = false)
    $osu.post "/forum/ucp.php?mode=login", { username: ENV['OSULOGIN'], password: ENV['OSUPASS'], autologin: 'on', sid: '', login: 'login' }
    beatmap = $osu.get "/d/#{beatmapid}n"
    beatmapdata = get_beatmap_info(beatmapid)
    filename = "#{beatmapid} #{beatmapdata['artist']} - #{beatmapdata['title']}"
    filename.gsub! '~', '-'
    filename.gsub! '/', '-'
    filename.gsub! '*', '-'
    filename.gsub! '"', ''
    filename.gsub! "'", ''
    filename.gsub! '?', '-'
    filename.gsub! ':', '-'
    io = UploadIO.new(StringIO.new(beatmap.body), beatmap.headers[:content_type], "#{filename}.osz")
    $fd.post "/bot#{ENV['TOKEN']}/sendDocument", {
        :chat_id => userid,
        :caption => "Your beatmap was succesfully downloaded! BeatmapID = #{beatmapid}",
        :reply_to_message_id => messageid,
        :document => io
    } unless mode

    if mode
      #res = $upload.post '/upload.php', {
      #    :files => [io]
      #}
      #puts res.body
      #url = res.body['url']
      chanid = -1001083216506
      res = $fd.post "/bot#{ENV['TOKEN']}/sendDocument", {
          :chat_id => chanid,
          :document => io
      }
      puts res.body
      fid = JSON.parse(res.body)['result']['document']['file_id']
      answer = [
          {
              :type => 'document',
              :id => beatmapid,
              :title => filename,
              :document_file_id => fid
          }
      ]
      res = $fd.post "/bot#{ENV['TOKEN']}/answerInlineQuery", {
          :inline_query_id => userid,
          :results => answer.to_json
      }
      puts res.body
    end
  end
end