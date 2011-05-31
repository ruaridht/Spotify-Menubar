//
//  AppController.h
//  Spotify Menubar
//
//  Created by Ruaridh Thomson on 06/06/2010.
//  Copyright 2010 Life Up North/Ruaridh Thomson. All rights reserved.
//
//	This software is distributed under licence. Use of this software
//	implies agreement with all terms and conditions of the accompanying
//	software licence.

#import <Cocoa/Cocoa.h>

#import <ShortcutRecorder/ShortcutRecorder.h>
#import <SDGlobalShortcuts/SDGlobalShortcuts.h>

@interface AppController : NSObject {
	
	NSOperationQueue *queue;
	NSTimer *spotifyChecker;
	
	// Process Stuff
	int numberOfProcesses;
	NSMutableArray *processList;
	int processID;
	
	IBOutlet NSTextField *textfield;
	
	int _selectedPID;
	int _lastAttachedPID;
		
	CGEventSourceRef theSource;
	
	// Status menu stuff
	NSStatusItem *statusItem;
	NSStatusItem *playItem;
	NSStatusItem *fwrdItem;
	NSStatusItem *backItem;
	
	IBOutlet NSView *statusView;
	IBOutlet NSMenu *statusMenu;
	
	// Interface Stuff
	IBOutlet NSWindow *welcomeWindow;
	
	IBOutlet SRRecorderControl *playPauseRecorder;
	IBOutlet SRRecorderControl *skipForwardRecorder;
	IBOutlet SRRecorderControl *skipBackRecorder;

	KeyCombo ppGlobalHotkey;
	KeyCombo sfGlobalHotkey;
	KeyCombo sbGlobalHotkey;
	
	IBOutlet NSButton *showDockIcon;
	IBOutlet NSButton *showMenubarIcon;
	IBOutlet NSButton *openAtLogin;
	IBOutlet NSButton *showWelcomeWindow;
	IBOutlet NSButton *openSpotifyOnLaunch;
	IBOutlet NSButton *openSpotifyOnKeybind;
	
	// Hidden Interface Stuff
	IBOutlet NSButton *playPauseButton;
	IBOutlet NSButton *skipForwardButton;
	IBOutlet NSButton *skipBackButton;
	
	// Preferences Stuff
	IBOutlet NSWindow *prefWindow;
	
	NSView *currentView;
	IBOutlet NSView *prefContentView;
	
	IBOutlet NSView *generalView;
	IBOutlet NSView *shortcutsView;
	IBOutlet NSView *helpView;
	IBOutlet NSView *aboutView;
	IBOutlet NSView *simbleView;
	
	IBOutlet NSToolbar *prefToolbar;
	IBOutlet NSToolbarItem *generalToolbarItem;
	IBOutlet NSToolbarItem *shortcutsToolbarItem;
	IBOutlet NSToolbarItem *advancedToolbarItem;
	IBOutlet NSToolbarItem *helpToolbarItem;
	IBOutlet NSToolbarItem *aboutToolbarItem;
	IBOutlet NSToolbarItem *simblToolbarItem;
	
	IBOutlet NSPopUpButton *menubarIconStyle;
	
}

- (int)numberOfProcesses;
- (void)obtainFreshProcessList;
- (BOOL)findProcessWithName:(NSString *)procNameToSearch;

- (IBAction)checkForProcesses:(id)sender;
- (IBAction)findProcessesWithName:(id)sender;

- (ProcessSerialNumber)getSpotifyProcessSerialNumber;
- (CGEventSourceRef)source;

- (NSOperationQueue *)operationQueue;
- (void)checkIsSpotifyActive;
- (BOOL)isSpotifyActive;

- (void)sendPlayPauseThreaded;
- (void)sendSkipBackThreaded;
- (void)sendSkipForwardThreaded;
- (void)pressHotkey: (int)hotkey withModifier: (unsigned int)modifier;

- (IBAction)openPreferences:(id)sender;
- (IBAction)openSpotifyPreferences:(id)sender;
- (IBAction)resetKeybinds:(id)sender;
- (IBAction)toggleOpenAtLogin:(id)sender;
- (void)toggleMenuForMiniControls;
- (IBAction)toggleMiniControls:(id)sender;
- (IBAction)switchMenubarIconStyle:(id)sender;

- (IBAction)openAboutWindow:(id)sender;
- (IBAction)switchPreferenceView:(id)sender;
- (void)loadView:(NSView *)theView;

- (IBAction)sendPlayPause:(id)sender;
- (IBAction)sendSkipForward:(id)sender;
- (IBAction)sendSkipBack:(id)sender;
- (IBAction)sendKeystroke:(id)sender;

- (IBAction)syncroniseUserDefaults:(id)sender;
- (IBAction)openURLLifeUpNorth:(id)sender;
- (IBAction)sendLUNemail:(id)sender;
- (IBAction)openUrlSimbl:(id)sender;
- (IBAction)openUrlLunPlugin:(id)sender;

- (void)setStatusItem;
- (void)addAppAsLoginItem;
- (void)deleteAppFromLoginItem;
- (IBAction)setApplicationIsAgent:(id)sender;
- (BOOL)shouldBeUIElement;
- (void)setShouldBeUIElement:(BOOL)hidden;

@end
