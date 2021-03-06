require 'hpricot'
require 'open-uri'

class Youtube
  attr_accessor :video_id, :url, :provider, :title, :description, :keywords,
                :duration, :date, :width, :height,
                :thumbnail_small, :thumbnail_large,
                :view_count

  def initialize(url)
    case url
    when /user/
      @video_id = url.split("/").last
    when /youtube\.com/
      @video_id = url.gsub(/.*v=([^&]+).*$/i, '\1')
    when /youtu\.be/
      @video_id = url.split("/").last
    end
    get_info unless @video_id == url
  end

private

  def get_info
    begin
      xml = open("http://gdata.youtube.com/feeds/api/videos/#{@video_id}")
    rescue
      return nil
    end
    doc = Hpricot(xml)

    @provider         = "YouTube"
    @url              = "http://www.youtube.com/watch?v=#{@video_id}"
    @title            = doc.search("media:title").inner_text
    @description      = doc.search("media:description").inner_text
    @keywords         = doc.search("media:keywords").inner_text
    @duration         = doc.search("yt:duration").first[:seconds].to_i if doc.search("yt:duration").first.present?
    @date             = Time.parse(doc.search("published").inner_text, Time.now.utc)
    @thumbnail_small  = doc.search("media:thumbnail").min { |a,b| a[:height].to_i * a[:width].to_i <=> b[:height].to_i * b[:width].to_i }[:url]
    @thumbnail_large  = doc.search("media:thumbnail").max { |a,b| a[:height].to_i * a[:width].to_i <=> b[:height].to_i * b[:width].to_i }[:url]
    # when your video still has no view, yt:statistics is not returned by Youtube
    # see: https://github.com/thibaudgg/video_info/issues#issue/2
    if doc.search("yt:statistics").first
      @view_count     = doc.search("yt:statistics").first[:viewcount].to_i
    else
      @view_count     = 0
    end
  end

end