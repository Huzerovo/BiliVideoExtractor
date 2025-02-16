# BiliBili缓存视频提取器

用于提取BiliBili客户端里缓存视频，合并成一个视频。

# 依赖

- **bash**
- **ffmpeg**
- **Python >= 3.9**

# 用法示例

仅支持Linux上使用，使用方式：

1. 提取缓存视频文件，例如使用adb提取：
   ```sh
   mkdir bilibili-video
   cd bilibili-video
   adb pull /sdcard/Android/data/tv.danmaku.com/download
   ```
2. 克隆本项目
   ```sh
   git clone "https://github.com/Huzerovo/BiliVideoExtractor.git"
   ```
3. 运行脚本
   ```sh
   chmod +x ./BiliVideoExtractor/bili-extract-video.sh 
   # 查看帮助
   ./BiliVideoExtractor/bili-extract-video.sh --help
   # 使用默认参数运行
   ./BiliVideoExtractor/bili-extract-video.sh
   ```

文件将输出到`output`文件夹
