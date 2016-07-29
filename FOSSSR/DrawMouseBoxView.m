//
//  DrawMouseBoxView.m
//  FOSSSR
//
//  Created by Andrew Mellen on 7/28/16.
//  Copyright © 2016 theawesomecoder61. All rights reserved.
//

#import "DrawMouseBoxView.h"

@implementation DrawMouseBoxView {
	NSPoint _mouseDownPoint;
	NSRect _selectionRect;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
	return YES;
}

- (BOOL)acceptsFirstResponder {
	return YES;
}

- (void)mouseDown:(NSEvent *)theEvent {
	_mouseDownPoint = [theEvent locationInWindow];
}

- (void)mouseUp:(NSEvent *)theEvent {
	NSPoint mouseUpPoint = [theEvent locationInWindow];
	NSRect selectionRect = NSMakeRect(
		MIN(_mouseDownPoint.x, mouseUpPoint.x), 
		MIN(_mouseDownPoint.y, mouseUpPoint.y), 
		MAX(_mouseDownPoint.x, mouseUpPoint.x) - MIN(_mouseDownPoint.x, mouseUpPoint.x),
		MAX(_mouseDownPoint.y, mouseUpPoint.y) - MIN(_mouseDownPoint.y, mouseUpPoint.y));
	[self.delegate drawMouseBoxView:self didSelectRect:selectionRect];
}

- (void)mouseDragged:(NSEvent *)theEvent {
	NSPoint curPoint = [theEvent locationInWindow];
	NSRect previousSelectionRect = _selectionRect;
	_selectionRect = NSMakeRect(
		MIN(_mouseDownPoint.x, curPoint.x), 
		MIN(_mouseDownPoint.y, curPoint.y), 
		MAX(_mouseDownPoint.x, curPoint.x) - MIN(_mouseDownPoint.x, curPoint.x),
		MAX(_mouseDownPoint.y, curPoint.y) - MIN(_mouseDownPoint.y, curPoint.y));
	[self setNeedsDisplayInRect:NSUnionRect(_selectionRect, previousSelectionRect)];
}

- (void)drawRect:(NSRect)dirtyRect {
	[[NSColor blackColor] set];
	NSRectFill(dirtyRect);
	[[NSColor whiteColor] set];
	NSFrameRect(_selectionRect);
}

@end
