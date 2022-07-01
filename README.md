# mpv-gif-generator *for windows*

![Yuri On Ice Example](https://i.imgur.com/6wIylNl.gif)

A fork of [the_honey](https://github.com/the-honey)'s script found [here](https://github.com/the-honey/mpv-gif-generator). I added a functionality to create automatic screenshots every 10 seconds.


# Requirements 
- Windows
- mpv
- ffmpeg with libass enabled–as long as you're using the zeronoe builds you're good!
 
# Installation

First of all, you must make sure `ffmpeg` is in your `%PATH%` and accesible via your command line. After ensuring this, clone or download as zip. Then, head to `%APPDATA%/mpv/scripts` and place `mpv-gif.lua` in there; if neither `%APPDATA%/mpv` nor `%APPDATA%/mpv/scripts` exist, you will have to create them. It's as easy as that!

# Configuration

After setup, and if you wish, create a `%APPDATA%/mpv/script-opts` directory if it isn't created already and write a `gif.conf` file to configure the script. Here's a sample configuration file:
```
dir="C:/Users/%USERNAME%/Pictures/mpv_gifs"
screenshots_dir="C:/Users/%USERNAME%/Pictures/mpv_screenshots"
gif_rez=320
screenshot_rez=320
fps=10
```

 
## Hotkeys
### GIF
* `G` - Gif start time
* `SHIFT+G` - Gif end time
* `CTRL+G` - Export GIF
* `CTRL+SHIFT+G` - Export GIF with subtitles
### Screenshots
* `ALT+S` - Take screenshots every 10 seconds.
* `ALT+SHIFT+S` - Take screenshots every 10 seconds with subtitles.
