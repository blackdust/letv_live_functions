# letv_live_functions

## 基础配置
在别的ruby文件中引入此类:
```ruby
#require 路径 + letv_live_room
require "./letv_live_room"

#初始化类，需要输入乐视云直播平台里个人信息的 用户ID 私钥 UUID。
LetvLiveRoom.set_userid("123456")
LetvLiveRoom.set_secretkey("abc")
LetvLiveRoom.set_uu("cba")

```
## 模型上的查询方法
先声明一个直播实例：
```ruby
live = LetvLiveRoom.new
```

### 模块一(创建直播活动)
```ruby
#不传参数直接创建 会默认创建 长度为40分钟，随机字符串名字的活动名称
live.create_letv_live
#可传参数（活动名称, 活动时间（分钟））
live.create_letv_live("xxx", 10)
```

```ruby
#该方法执行成功后会返回乐视云直播平台上的直播活动id
  "A2016080900002ho"
```

### 模块二(获取推流url和推流码)
```ruby
live.get_obs_url_and_code
```
```ruby
 {
   :obs_url=>"rtmp://w.gslb.lecloud.com/live", 
   :obs_code=>"201608093000003ll99?sign=9ecde1168b9dc9a4daf1f7689ee20a20&tm=20160809165616"
 }
```

### 模块三(获取机位状态)
```ruby
  live.get_live_state
```
```ruby
  #返回bool true和false分别表示有无信号
  false
```

### 模块四(获得播放页面)
```ruby
  live.get_live_video_play_url
```
```ruby
  "http://t.cn/RtNyGK7"
```

### 模块五(获取录制界面)
```ruby
  live.get_saved_video_url
```
```ruby
  #在直播结束后乐视云直播服务允许录制并存储在乐视云点播上，以下是在正确时间内启动命令，save_state还有可能是"录制失败","转码完成", 转码失败"
 {
   :web_url=>"http://yuntv.letv.com/bcloud.htmluu=xet&vu=97c4pu=12345abcde&auto_play=1&width=800&height=450",
   :save_state=>"录制完成正在转码"
 }
  #如果在直播没有人播和直播未结束时启动命令则会：
  {:save_state=>"直播未结束或重未开启"}
```

### 模块六(结束直播活动)
```ruby
  live.finish_live_video
```
```ruby
  #正确关闭 "finished" 出现错误则 "error"
  "finished"
```
