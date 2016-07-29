//
//  DrawMouseBoxView.h
//  FOSSSR
//
//  Created by Andrew Mellen on 7/28/16.
//  Copyright © 2016 theawesomecoder61. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class DrawMouseBoxView;

@protocol DrawMouseBoxViewDelegate<NSObject>

- (void)drawMouseBoxView:(DrawMouseBoxView*)view didSelectRect:(NSRect)rect;

@end


@interface DrawMouseBoxView : NSView

@property(readwrite, weak) id <DrawMouseBoxViewDelegate> delegate;

@end