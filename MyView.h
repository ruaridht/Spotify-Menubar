//
//  MyView.h
//  Spotify Menubar
//
//  http://stackoverflow.com/questions/4565820/cocoa-right-click-nsstatusitem
//

#import <Cocoa/Cocoa.h>

@interface MyView : NSControl {
	NSImage *image;
	id target;
	SEL action, rightAction;
}

@property (retain) NSImage *image;
@property (assign) id target;
@property (assign) SEL action, rightAction;

@end
