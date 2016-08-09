require 'digest/md5'
require 'uri'
require 'net/http'
require 'net/https'
require 'json'  

class LetvLiveRoom
  class << self
    def set_userid(str)
      @@userid = str
    end

    def set_secretkey(str)
      @@secretkey = str
    end

    def set_uu(str)
      @@uu = str
    end
  end

  def initialize
  end
  
  # 模块一(创建直播活动)
  def create_letv_live(name = nil , time = nil)
    name ||= [*('a'..'z'), *('A'..'Z'), *(0..9)].shuffle[0..9].join
    time ||= 40
    params = {
      :method => 'lecloud.cloudlive.activity.create',
      :ver => '3.1',
      :userid => @@userid,
      :timestamp => Time.now.to_i * 1000,
      :activityName => name,
      :startTime => Time.now.strftime("%Y%m%d%H%M%S"),
      :endTime   => Time.at(Time.now.to_i + 60 * time).strftime("%Y%m%d%H%M%S"),
      :liveNum => 1,
      :codeRateTypes => "10,13,16,19,22,25",
      :needRecord => 1,
      :needTimeShift => 0,
      :needFullView => 0,
      :activityCategory => "012",
      :playMode => 0
    }
    params[:sign] = make_sign_str(params)
    url = URI.parse("http://api.open.letvcloud.com/live/execute")
    Net::HTTP.start(url.host, url.port) do |http|
      req = Net::HTTP::Post.new(url.path)
      req.set_form_data(params)
      @activity_id = JSON.parse(http.request(req).body)["activityId"]
    end
    @activity_id
  end

  def make_sign_str(hash)
    Digest::MD5.hexdigest(hash.sort_by{|k,v| k}.map{|k,v| k.to_s + v.to_s}.join() + @@secretkey)
  end

  # 模块二(获取推流url和推流码)
  def get_obs_url_and_code
    push_url_params = {
      :method => "lecloud.cloudlive.activity.getPushUrl",
      :ver => '3.1',
      :userid => @@userid,
      :timestamp => Time.now.to_i * 1000,
      :activityId => @activity_id,
    }
    push_url_params[:sign] = make_sign_str(push_url_params)
    str = push_url_params.map{|k,v| "&" + k.to_s + "=" + v.to_s}.join()
    str[0] = ""
    uri = URI("http://api.open.letvcloud.com/live/execute" + "?" + str)
    @pushUrl = JSON.parse(Net::HTTP.get(uri))
    return_hash = {}
    return_hash[:obs_url]  = "rtmp://w.gslb.lecloud.com/live"
    return_hash[:obs_code] = @pushUrl["lives"][0]["pushUrl"].gsub(return_hash[:obs_url] + "/", "")
    return_hash
  end

  # 模块三(获取机位状态)
  def get_live_state
     params = {
      :method => 'letv.cloudlive.activity.getActivityMachineState',
      :ver => '3.1',
      :userid => @@userid,
      :timestamp => Time.now.to_i * 1000,
      :activityId => @activity_id
    }
    params[:sign] = make_sign_str(params)
    str = params.map{|k,v| "&" + k.to_s + "=" + v.to_s}.join()
    str[0] = ""
    uri = URI("http://api.open.letvcloud.com/live/execute" + "?" + str)
    @live_id = JSON.parse(Net::HTTP.get(uri))["lives"][0]["liveId"]
    JSON.parse(Net::HTTP.get(uri))["lives"][0]["status"] == "1"? true:false
  end

  # 模块四(获得播放页面)
  def get_live_video_play_url
    params = {
      :method => 'lecloud.cloudlive.activity.playerpage.getUrl',
      :ver => '3.1',
      :userid => @@userid,
      :timestamp => Time.now.to_i * 1000,
      :activityId => @activity_id
    }
    params[:sign] = make_sign_str(params)
    str = params.map{|k,v| "&" + k.to_s + "=" + v.to_s}.join()
    str[0] = ""
    uri = URI("http://api.open.letvcloud.com/live/execute" + "?" + str)
    JSON.parse(Net::HTTP.get(uri))["playPageUrl"]
  end

  # 模块五(获取录制界面)
  def get_saved_video_url
    if @live_id.nil?
      self.get_live_state
    end
    params = {
      :method => 'lecloud.cloudlive.rec.searchResult',
      :ver => '3.1',
      :userid => @@userid,
      :timestamp => Time.now.to_i * 1000,
      :liveId => @live_id
    }
    params[:sign] = make_sign_str(params)
    str = params.map{|k,v| "&" + k.to_s + "=" + v.to_s}.join()
    str[0] = ""
    uri = URI("http://api.open.letvcloud.com/live/execute" + "?" + str)
    return_hash = {}
    if !JSON.parse(Net::HTTP.get(uri))["rows"][0].nil?
      vu = JSON.parse(Net::HTTP.get(uri))["rows"][0]["videoUnique"]
      return_hash[:web_url] = "http://yuntv.letv.com/bcloud.html?uu=#{@@uu}&vu=#{vu}&pu=12345abcde&auto_play=1&width=800&height=450"
      return_hash[:save_state] = convert_saved_video_state_code(JSON.parse(Net::HTTP.get(uri))["rows"][0]["status"])
    else
      return_hash[:save_state] = "直播未结束或重未开启"
    end
    return_hash
  end

  # 模块六(结束直播活动)
  def finish_live_video
    params = {
      :method => 'lecloud.cloudlive.activity.stop',
      :ver => '3.1',
      :userid => @@userid,
      :timestamp => Time.now.to_i * 1000,
      :activityId => @activity_id
    }
    params[:sign] = make_sign_str(params)
    url = URI.parse("http://api.open.letvcloud.com/live/execute")
    Net::HTTP.start(url.host, url.port) do |http|
      req = Net::HTTP::Post.new(url.path)
      req.set_form_data(params)
      http.request(req).code == "200" ? "finished" : "error" 
    end
  end

  def convert_saved_video_state_code(num)
    hash = {"3" => "录制完成正在转码", "6" => "录制失败", "7" => "转码完成", "8" => "转码失败"}
    hash[num.to_s]
  end
end


# LetvLiveRoom.set_userid(123456)
# LetvLiveRoom.set_secretkey("-----------")
# LetvLiveRoom.set_uu("xxx")



