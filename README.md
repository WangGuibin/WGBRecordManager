# WGBRecordManager

关于ReplayKit框架的介绍网上也很多,目前有以下几种实现方式
* 录制本地视频 (`startRecordingWithHandler`)
	* 弹出系统的预览控制器进行分享/保存/编辑
	* 获取录制的视频保存至相册或者沙盒再进行自定义UI 

* 录制数据流 
	* 通过流媒体传输协议上传至服务器,也就是直播 (基于rtmp或者rtp)
	* 通过Extension录制和上传 


## 应用场景

* 1. 游戏直播 (王者荣耀/和平精英/...)
* 2. 影视片段录制⏺ (拒绝盗版 Apple官方文档也是说不能和AVPlayer内容不兼容啥的,iPhone XR iOS14.3 实测没问题但估计会不让上架) 
* 3. 开发测试保留case,用于复现过程 
* 4. 还有很多知识盲区,应用场景应该还是很广泛的...   

## 实例

|录屏权限获取|预览|
|:--:|:--:|
|![](https://cdn.jsdelivr.net/gh/WangGuibin/MyFilesRepo/images/20210220233804.png)|![](https://cdn.jsdelivr.net/gh/WangGuibin/MyFilesRepo/images/20210220233819.png)|

* 1. 本地视频自定义预览UI 参考[Demo](https://github.com/WangGuibin/WGBRecordManager)
* 2. rtmp推流到服务器 [LFLiveKit-ReplayKit](https://github.com/FranLucky/LFLiveKit-ReplayKit)或者参考直播框架[LFLiveKit](https://github.com/LaiFengiOS/LFLiveKit) 
* 3. Extension BoardCast 这个暂未实现,可参考声网或者腾讯云SDK的实现

## 参考文章
* [iOS ReplayKit 与 RTC](https://blog.csdn.net/agora_cloud/article/details/113248712)
* [苹果内置录屏SDK-ReplayKit库的使用说明](https://www.cnblogs.com/huangzizhu/p/5073389.html)
* [iOS录屏框架ReplayKit的应用总结](https://cloud.tencent.com/developer/article/1627597?from=information.detail.replaykit)
* [腾讯云直播SDK录屏推流iOS](https://cloud.tencent.com/document/product/454/7883)


