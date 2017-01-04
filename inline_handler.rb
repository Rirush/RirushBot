require './define'
require './beatmap_download'
require 'sucker_punch'

class InlineHandler
  include SuckerPunch::Job

  def perform(querydata, querytext)
    osu = /http(?:|s):\/\/osu.ppy.sh\/s\/(?<id>\d+)/i.match(querytext)
    BeatmapDownload.perform_async(osu['id'], querydata['id'], -1, true) if osu != nil
  end
end