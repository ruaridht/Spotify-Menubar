//
//  MyView.m
//  Spotify Menubar
//
//  http://stackoverflow.com/questions/4565820/cocoa-right-click-nsstatusitem
//

#import "MyView.h"

@implementation MyView

@synthesize image, target, action, rightAction;

- (void)mouseUp:(NSEvent *)event {
    if([event modifierFlags] & NSControlKeyMask) {
        [NSApp sendAction:self.rightAction to:self.target from:self];
    } else {
        [NSApp sendAction:self.action to:self.target from:self];
    }
}

- (void)rightMouseUp:(NSEvent *)event {
    [NSApp sendAction:self.rightAction to:self.target from:self];
}

- (void)dealloc {
    self.image = nil;
    [super dealloc];
}

- (void)drawRect:(NSRect)rect {
	NSRect customRect = NSMakeRect(5, 3, 16, 16); // Haha! Hack :<
    [self.image drawInRect:customRect /*self.bounds*/ fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
}

@end
