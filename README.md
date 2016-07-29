# FOSSR
A **F**ree, **O**pen-**S**ource **S**creen **R**ecorder for Mac OS X 10.8+.

## [Download here](https://github.com/theawesomecoder61/FOSSR/releases)
This will take you to the releases page.

## Features
- Records the entire display
- Choose which display to record
- Set the framerate/FPS (5, 10, 15, 25, 30, 45, 60 FPS)
- Show/hide the mouse
- Show/hide mouse clicks
- Remove duplicate frames (for smoother-looking video)
- Countdown from 0 to 10 seconds

## How it works
Mac OS X and iOS have a framework named *AVFoundation*. This framework handles audio and video input/output, such as audio players or video camera capture. Here is what goes on in the meat of the code:

1. It creates an *AVCaptureSession*, this allows inputs of audio and video, quite necessary
2. It creates an *AVCaptureScreenInput*, this allows us to capture the screen
3. It adds the *AVCaptureScreenInput* to the session, otherwise our session wouldn't have anything in it
4. It initiates a *AVCaptureMovieFileOutput*, so we can export the captured screen data to a file as an *.mov*
5. It adds the *AVCaptureMovieFileOutput* to the session
6. It runs the session
7. Once the user clicks *Record* and selects a place to record to, it begins to record and write data once *Stop* is clicked

## Screenshots
### Main Window
![](http://i.imgur.com/LBDDzjl.png)
### *Record to* window
![](http://i.imgur.com/RZxy5Cu.png)
### Countdown (an optional feature)
![](http://i.imgur.com/vF8NTbn.png)
### Configure window
To close the window, click the red circle or push *Escape*.
![](http://i.imgur.com/zC9azZd.png)

## Building for yourself
1. Make sure Xcode is installed
2. Download the repo as a ZIP or clone the repo
3. Open the project in Xcode and run the project
4. Enjoy!

## Planned features
Italics indicate a urgent future bug fix.
- A demo video on YouTube
- Set the quality of the video
- Microphone recording
- Record a rectangular selection on the screen
- Record a window?

## The *.circles* file in `icons/`
*.circles* files can be created/edited/viewed with [CircleIcons](http://www.bayhoff.com/circleicons/index.html). I am not affiliated or endorsed with the developer of CircleIcons.

## Licenses
Since I'm too lazy to put the licenses here, I'll provide links to them.
- [DJProgressHUD_OSX](https://github.com/danielmj/DJProgressHUD_OSX/blob/master/LICENSE.txt)
- [MKBOSXCloseButton](https://github.com/Megatron1000/MKBOSXCloseButton/blob/master/LICENSE)
