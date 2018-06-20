# TSClipEditor
<p align="center">
  <img src="https://github.com/shion0111/TSClipEditor/blob/master/screen/v1.jpg" width="480"/>
  <img src="https://github.com/shion0111/TSClipEditor/blob/master/screen/v2.jpg" width="480"/>
  <img src="https://github.com/shion0111/TSClipEditor/blob/master/screen/v3.jpg" width="640"/>
</p>

A TS clip exporter (mainly those huge MPEG2-TS files) on OSX. User can choose several ranges of a video on a customized slider by setting multiple thumbs and then save clips.

** A hobby project and a case-study of ffmpeg **

## Prerequisites
- [ffmpeg](https://github.com/FFmpeg)
- VLCKit via cocoapods (The pod files are not included in this repo. After cloning you need to run "pod install" to get the cocoapod files. Then you should be able to open the workspace and build.)

## Compatibility
- OS X 10.10 or later

## Requirements
- Xcode 8.0
- Swift 3.0

## Tasks in progress
- ~~Issue: memory consuming when decoding video~~
- ~~UI redesign~~ 
- Clip preview (current solution: VLCKit)

## To do
- Support for other formats


