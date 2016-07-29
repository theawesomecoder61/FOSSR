//
//  AppDelegate.m
//  FOSSSR
//
//  Created by Andrew Mellen on 7/28/16.
//  Copyright © 2016 theawesomecoder61. All rights reserved.
//

#import "AppDelegate.h"
#import <AVFoundation/AVFoundation.h>
#import <ScriptingBridge/ScriptingBridge.h>
#import "DJActivityIndicator.h"
#import "DJProgressIndicator.h"
#import "DJProgressHUD.h"

#define kShadyWindowLevel (NSDockWindowLevel + 1000)

@interface AppDelegate ()

- (IBAction)startRecording:(id)sender;
- (IBAction)stopRecording:(id)sender;

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSToolbar *toolbar;
@property (weak) IBOutlet NSView *captureView;
@property (weak) IBOutlet NSMenuItem *beginRecMI;
@property (weak) IBOutlet NSMenuItem *stopRecMI;
@property (weak) IBOutlet NSToolbarItem *recordBtn;
@property (weak) IBOutlet NSToolbarItem *stopBtn;

@property (weak) IBOutlet NSMenu *mbMenu;
@property (weak) IBOutlet NSMenuItem *beginRecMBMI;
@property (weak) IBOutlet NSMenuItem *stopRecMBMI;

@property (weak) IBOutlet NSWindow *configureWindow;
@property (weak) IBOutlet NSSlider *countdownSlider;
@property (weak) IBOutlet NSTextField *countdownTF;
@property (weak) IBOutlet NSPopUpButton *displayPicker;
@property (weak) IBOutlet NSPopUpButton *fpsPicker;
@property (weak) IBOutlet NSButton *capturesMouseClicks;
@property (weak) IBOutlet NSButton *capturesCursor;
@property (weak) IBOutlet NSButton *removesDuplicateFrames;
@property (weak) IBOutlet NSButton *recordMicCB;
@end

static float prog = 0;

@implementation AppDelegate {
    CGDirectDisplayID display;
    AVCaptureMovieFileOutput *captureMovieFileOutput;
    NSMutableArray *shadeWindows;
    NSTimer *timer;
    NSStatusItem *statusItem;
    NSURL *recordPath;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // menubar
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [statusItem setMenu:self.mbMenu];
    NSImage *img = [NSImage imageNamed:@"Shutter"];
    [img setSize:NSMakeSize(18, 18)];
    [statusItem setImage:img];
    [statusItem.image setTemplate:YES];
    [statusItem setHighlightMode:YES];
    
    // add all displays into list
    [self.displayPicker.menu removeAllItems];
    for(int i=0;i<[NSScreen screens].count;i++) {
        [self.displayPicker.menu addItemWithTitle:[NSString stringWithFormat:@"Display %d", i+1] action:nil keyEquivalent:@""];
    }
    
    // set defaults
    [self.fpsPicker selectItemWithTitle:@"30"];
    [self.countdownSlider setIntValue:3];
    
    [self updateBtns:0];
    [self addCaptureVideoPreview];
    [self setupRecording];
    [self.window setMovableByWindowBackground:YES];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureSessionRuntimeErrorNotification object:self.captureSession];
    [self.captureSession stopRunning];
    NSLog(@"! RECORDING HAS STOPPED !");
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {
    [self.window makeKeyAndOrderFront:self];
    return YES;
}


//
// CONFIGURATION
//
- (void)addCaptureVideoPreview {
    AVCaptureVideoPreviewLayer *videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
    
    [videoPreviewLayer setFrame:[[self.captureView layer] bounds]];
    [videoPreviewLayer setAutoresizingMask:kCALayerWidthSizable |kCALayerHeightSizable];
    
    [[self.captureView layer] addSublayer:videoPreviewLayer];
    [[self.captureView layer] setBackgroundColor:CGColorGetConstantColor(kCGColorBlack)];
}

- (IBAction)countdownChange:(id)sender {
    [self.countdownTF setStringValue:[NSString stringWithFormat:@"%d", [sender intValue]]];
}

- (void)setupRecording {
    self.captureSession = [[AVCaptureSession alloc] init];
    self.captureSession.sessionPreset = AVCaptureSessionPresetHigh;
    
    CGDirectDisplayID displayId = kCGDirectMainDisplay;
    
    AVCaptureScreenInput *input = [[AVCaptureScreenInput alloc] initWithDisplayID:displayId];
    [input setCapturesCursor:[self.capturesCursor state]];
    [input setCapturesMouseClicks:([self.capturesMouseClicks state]&&[self.capturesMouseClicks isEnabled])];
    [input setRemovesDuplicateFrames:[self.removesDuplicateFrames state]];
    
    //  FPS
    int maximumFramerate = [[[self.fpsPicker selectedItem] title] intValue];
    CMTime minimumFrameDuration = CMTimeMake(1, (int32_t)maximumFramerate);
    [input setMinFrameDuration:minimumFrameDuration];
    
    if(!input) {
        self.captureSession = nil;
        return;
    }
    
    if([self.captureSession canAddInput:input]) {
        [self.captureSession addInput:input];
    }
    
    // capture screen
    captureMovieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    if([self.captureSession canAddOutput:captureMovieFileOutput]) {
        [self.captureSession addOutput:captureMovieFileOutput];
    }
    
    // run the session
    [self.captureSession startRunning];
}


//
// BUTTONS
//
- (IBAction)startRecording:(id)sender {
    NSSavePanel *sp = [NSSavePanel savePanel];
    [sp setTitle:@"Record to"];
    [sp setAllowedFileTypes:@[@"mov"]];
    if([sp runModal] == NSModalResponseOK) {
        recordPath = [sp URL];
        [self updateBtns:-1];
        [DJProgressHUD showProgress:0 withStatus:@"Recording in..." FromView:self.window.contentView];
        [timer invalidate];
        timer = nil;
        timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(countdown) userInfo:nil repeats:YES];
    }
}

- (void)countdown {
    prog += (1.0/[self.countdownSlider floatValue]);
    
    if(prog > 1.1) {
        [DJProgressHUD dismiss];
        prog = 0;
        [timer invalidate];
        timer = nil;
        [self.window orderOut:self];
        NSLog(@"Minimum Frame Duration: %f, Crop Rect: %@, Scale Factor: %f, Capture Mouse Clicks: %@, Capture Mouse Cursor: %@, Remove Duplicate Frames: %@",
              CMTimeGetSeconds([self.captureScreenInput minFrameDuration]),
              NSStringFromRect(NSRectFromCGRect([self.captureScreenInput cropRect])),
              [self.captureScreenInput scaleFactor],
              [self.capturesMouseClicks state] ? @"Yes" : @"No",
              [self.capturesCursor state] ? @"Yes" : @"No",
              [self.removesDuplicateFrames state] ? @"Yes" : @"No");
        [captureMovieFileOutput startRecordingToOutputFileURL:recordPath recordingDelegate:self];
    } else {
        [DJProgressHUD showProgress:prog withStatus:@"Recording in..." FromView:self.window.contentView];
    }
}

- (IBAction)stopRecording:(id)sender {
    [captureMovieFileOutput stopRecording];
    [self updateBtns:0];
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Screen Recording was Successful!"];
    [alert setInformativeText:@"Your screen recording recorded and saved succesfully!"];
    [alert addButtonWithTitle:@"Open QuickTime"];
    [alert addButtonWithTitle:@"Show in Finder"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
}
- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if(returnCode == NSAlertFirstButtonReturn) {
        id qt = [SBApplication applicationWithBundleIdentifier:@"com.apple.QuickTimePlayerX"];
        [qt activate];
    }
    if(returnCode == NSAlertSecondButtonReturn) {
        [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[recordPath]];
    }
    if(returnCode == NSAlertThirdButtonReturn) {
        [self.window endSheet:[alert window]];
    }
}
- (IBAction)configureRecording:(id)sender {
    [self.window beginSheet:self.configureWindow completionHandler:nil];
}
- (IBAction)closeConfigure:(id)sender {
    [self.window endSheet:self.configureWindow];
}

- (IBAction)reloadDisplays:(id)sender {
    [self.displayPicker.menu removeAllItems];
    for(int i=0;i<[NSScreen screens].count;i++) {
        [self.displayPicker.menu addItemWithTitle:[NSString stringWithFormat:@"Display %d", i+1] action:nil keyEquivalent:@""];
    }
    NSLog(@"! REFRESHED DISPLAYS LIST !");
}

- (IBAction)updateShowCursor:(id)sender {
    [self.capturesMouseClicks setEnabled:([sender state] == 1)];
}

- (void)updateBtns:(int)recordingMode {
    // 0 - no, 1 - yes, -1 - disable all
    // "disabling" by removing its action/selector
    if(recordingMode == 1) {
        [self.recordBtn setAction:nil];
        [self.stopBtn setAction:@selector(stopRecording:)];
        [self.beginRecMI setAction:nil];
        [self.stopRecMI setAction:@selector(stopRecording:)];
        [self.beginRecMBMI setAction:nil];
        [self.stopRecMBMI setAction:@selector(stopRecording:)];
    } else if(recordingMode == 0) {
        [self.recordBtn setAction:@selector(startRecording:)];
        [self.stopBtn setAction:nil];
        [self.beginRecMI setAction:@selector(startRecording:)];
        [self.stopRecMI setAction:nil];
        [self.beginRecMBMI setAction:@selector(startRecording:)];
        [self.stopRecMBMI setAction:nil];
    } else if(recordingMode == -1) {
        [self.recordBtn setAction:nil];
        [self.stopBtn setAction:nil];
        [self.beginRecMI setAction:nil];
        [self.stopRecMI setAction:nil];
        [self.beginRecMBMI setAction:nil];
        [self.stopRecMBMI setAction:nil];
    }
}


//
// MENUBAR
//
- (IBAction)showMainWindow:(id)sender {
    [self.window makeKeyAndOrderFront:self];
}
- (IBAction)quitApp:(id)sender {
    [NSApp terminate:self];
}


//
// NECESSARY
//
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    NSLog(@"! ERROR %@ - %@ !", [outputFileURL description], [error description]);
    [self.captureSession stopRunning];
    self.captureSession = nil;
}


//
// RECORDING
//
//- (BOOL)createCaptureSession:(NSError **)outError {
//    self.captureSession = [[AVCaptureSession alloc] init];
//    if([self.captureSession canSetSessionPreset:AVCaptureSessionPresetHigh]) {
//        [self.captureSession setSessionPreset:AVCaptureSessionPresetHigh];
//    }
//
//    /* Add the main display as a capture input. */
//    display = CGMainDisplayID();
//    self.captureScreenInput = [[AVCaptureScreenInput alloc] initWithDisplayID:display];
//
//    // add microphone input
//    AVCaptureDevice *microphone = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
//    AVCaptureDeviceInput *micIn = [[AVCaptureDeviceInput alloc] initWithDevice:microphone error:nil];
//
//    if([self.captureSession canAddInput:self.captureScreenInput]) {
//        [self.captureSession addInput:self.captureScreenInput];
//    } else  {
//        return NO;
//    }
//
//    if([self.recordMicCB state] == 1) {
//        if([self.captureSession canAddInput:micIn]) {
//            [self.captureSession addInput:micIn];
//        } else  {
//            return NO;
//        }
//    }
//
//    /* Add a movie file output + delegate. */
//    captureMovieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
//    [captureMovieFileOutput setDelegate:self];
//    if([self.captureSession canAddOutput:captureMovieFileOutput]) {
//        [self.captureSession addOutput:captureMovieFileOutput];
//    } else {
//        return NO;
//    }
//
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(captureSessionRuntimeErrorDidOccur:) name:AVCaptureSessionRuntimeErrorNotification object:self.captureSession];
//
//    return YES;
//}
//

//
//- (float)maximumScreenInputFramerate {
//    Float64 minimumVideoFrameInterval = CMTimeGetSeconds([self.captureScreenInput minFrameDuration]);
//    return minimumVideoFrameInterval > 0.0f ? 1.0f/minimumVideoFrameInterval : 0.0;
//}
//
//- (void)setMaximumScreenInputFramerate:(float)maximumFramerate {
//    CMTime minimumFrameDuration = CMTimeMake(1, (int32_t)maximumFramerate);
//    [self.captureScreenInput setMinFrameDuration:minimumFrameDuration];
//}
//
///* Add a display as an input to the capture session. */
//- (void)addDisplayInputToCaptureSession:(CGDirectDisplayID)newDisplay cropRect:(CGRect)cropRect {
//    [self.captureSession beginConfiguration];
//    if(newDisplay != display) {
//        [self.captureSession removeInput:self.captureScreenInput];
//        AVCaptureScreenInput *newScreenInput = [[AVCaptureScreenInput alloc] initWithDisplayID:newDisplay];
//        self.captureScreenInput = newScreenInput;
//        if([self.captureSession canAddInput:self.captureScreenInput]) {
//            [self.captureSession addInput:self.captureScreenInput];
//        }
//        [self setMaximumScreenInputFramerate:[self maximumScreenInputFramerate]];
//    }
//    [self.captureScreenInput setCropRect:cropRect];
//
//    [self.captureSession commitConfiguration];
//}
//
//- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
//    if(error) {
//        NSLog(@"%@", error);
//        return;
//    }
//    [[NSWorkspace sharedWorkspace] openURL:outputFileURL];
//}
//
//- (BOOL)captureOutputShouldProvideSampleAccurateRecordingStart:(AVCaptureOutput *)captureOutput {
//    return NO;
//}
//
//#pragma mark Crop Rect
//- (void)drawMouseBoxView:(DrawMouseBoxView*)view didSelectRect:(NSRect)rect {
//    /* Map point into global coordinates. */
//    NSRect globalRect = rect;
//    NSRect windowRect = [[view window] frame];
//    globalRect = NSOffsetRect(globalRect, windowRect.origin.x, windowRect.origin.y);
//    globalRect.origin.y = CGDisplayPixelsHigh(CGMainDisplayID()) - globalRect.origin.y;
//    CGDirectDisplayID displayID = display;
//    uint32_t matchingDisplayCount = 0;
//    /* Get a list of online displays with bounds that include the specified point. */
//    CGError e = CGGetDisplaysWithPoint(NSPointToCGPoint(globalRect.origin), 1, &displayID, &matchingDisplayCount);
//    if((e == kCGErrorSuccess) && (1 == matchingDisplayCount)) {
//        /* Add the display as a capture input. */
//        [self addDisplayInputToCaptureSession:displayID cropRect:NSRectToCGRect(rect)];
//    }
//
//    for(NSWindow* w in [NSApp windows]) {
//        if([w level] == kShadyWindowLevel) {
//            [w close];
//        }
//
//    }
//    [[NSCursor currentCursor] pop];
//    [shadeWindows removeAllObjects];
//}
//
//- (IBAction)setDisplayAndCropRect:(id)sender {
//    if(!shadeWindows) {
//        shadeWindows = [NSMutableArray array];
//    }
//
//    for(NSScreen *screen in [NSScreen screens]) {
//        NSRect frame = [screen frame];
//        NSWindow * window = [[NSWindow alloc] initWithContentRect:frame styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
//        [window setBackgroundColor:[NSColor blackColor]];
//        [window setAlphaValue:.5];
//        [window setLevel:kShadyWindowLevel];
//        [window setReleasedWhenClosed:NO];
//
//        DrawMouseBoxView* drawMouseBoxView = [[DrawMouseBoxView alloc] initWithFrame:frame];
//        drawMouseBoxView.delegate = self;
//        [window setContentView:drawMouseBoxView];
//        [window makeKeyAndOrderFront:self];
//        [shadeWindows addObject:window];
//    }
//
//    [[NSCursor crosshairCursor] push];
//}
//
//- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
//    // Do nothing
//}
//
//- (void)captureSessionRuntimeErrorDidOccur:(NSNotification *)notification {
//    NSError *error = [notification userInfo][AVCaptureSessionErrorKey];
//    NSAlert *alert = [[NSAlert alloc] init];
//    [alert setAlertStyle:NSCriticalAlertStyle];
//    [alert setMessageText:[error localizedDescription]];
//    NSString *informativeText = [error localizedRecoverySuggestion];
//    informativeText = informativeText ? informativeText : [error localizedFailureReason]; // No recovery suggestion, then at least tell the user why it failed.
//    [alert setInformativeText:informativeText];
//
//    [alert beginSheetModalForWindow:[self window] modalDelegate:self
// didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
//}
//
//
//#pragma mark Start/Stop Button Actions
//- (IBAction)startRecording:(id)sender {
//    NSLog(@"Minimum Frame Duration: %f, Crop Rect: %@, Scale Factor: %f, Capture Mouse Clicks: %@, Capture Mouse Cursor: %@, Remove Duplicate Frames: %@",
//          CMTimeGetSeconds([self.captureScreenInput minFrameDuration]),
//          NSStringFromRect(NSRectFromCGRect([self.captureScreenInput cropRect])),
//          [self.captureScreenInput scaleFactor],
//          [self.capturesMouseClicks state] ? @"Yes" : @"No",
//          [self.capturesCursor state] ? @"Yes" : @"No",
//          [self.removesDuplicateFrames state] ? @"Yes" : @"No");
//
//    /* Create a recording file */
//    char *screenRecordingFileName = strdup([[@"~/Desktop/AVScreenShackRecording_XXXXXX" stringByStandardizingPath] fileSystemRepresentation]);
//    if(screenRecordingFileName) {
//        int fileDescriptor = mkstemp(screenRecordingFileName);
//        if(fileDescriptor != -1) {
//            NSString *filenameStr = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:screenRecordingFileName length:strlen(screenRecordingFileName)];
//            [captureMovieFileOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:[filenameStr stringByAppendingPathExtension:@"mov"]] recordingDelegate:self];
//        }
//
//        remove(screenRecordingFileName);
//        free(screenRecordingFileName);
//    }
//}
//
//- (IBAction)stopRecording:(id)sender {
//    [captureMovieFileOutput stopRecording];
//}

@end