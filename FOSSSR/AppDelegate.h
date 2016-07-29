//
//  AppDelegate.h
//  FOSSSR
//
//  Created by Andrew Mellen on 7/28/16.
//  Copyright © 2016 theawesomecoder61. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>
#import <AVFoundation/AVCaptureOutput.h>
#import "DrawMouseBoxView.h"

@class AVCaptureSession, AVCaptureScreenInput, AVCaptureMovieFileOutput;

@interface AppDelegate : NSObject <NSApplicationDelegate, AVCaptureFileOutputRecordingDelegate>

@property (strong) AVCaptureSession *captureSession;
@property (strong) AVCaptureScreenInput *captureScreenInput;

@end