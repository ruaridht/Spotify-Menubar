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
#import "PTHeader.h"

#import <ShortcutRecorder/ShortcutRecorder.h>

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
	
	IBOutlet NSView *statusView;
	IBOutlet NSMenu *statusMenu;
	
	// Interface Stuff
	IBOutlet NSWindow *preferencesWindow;
	IBOutlet NSWindow *aboutWindow;
	IBOutlet NSWindow *welcomeWindow;
	
	IBOutlet SRRecorderControl *playPauseRecorder;
	IBOutlet SRRecorderControl *skipForwardRecorder;
	IBOutlet SRRecorderControl *skipBackRecorder;
	
	PTHotKey *playPauseGlobalHotkey;
	PTHotKey *skipForwardGlobalHotkey;
	PTHotKey *skipBackGlobalHotkey;
	
	IBOutlet NSButton *showDockIcon;
	IBOutlet NSButton *openAtLogin;
	IBOutlet NSButton *showWelcomeWindow;
	IBOutlet NSButton *openSpotifyOnLaunch;
	IBOutlet NSButton *openSpotifyOnKeybind;
	
	// Hidden Interface Stuff
	IBOutlet NSButton *playPauseButton;
	IBOutlet NSButton *skipForwardButton;
	IBOutlet NSButton *skipBackButton;
	
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

- (IBAction)sendPlayPause:(id)sender;
- (IBAction)sendSkipForward:(id)sender;
- (IBAction)sendSkipBack:(id)sender;
- (IBAction)sendKeystroke:(id)sender;

- (IBAction)syncroniseUserDefaults:(id)sender;
- (IBAction)openURLLifeUpNorth:(id)sender;
- (IBAction)sendLUNemail:(id)sender;

- (void)toggleGlobalHotKey:(SRRecorderControl*)sender;
- (void)shortcutRecorder:(SRRecorderControl *)recorder keyComboDidChange:(KeyCombo)newKeyCombo;

- (void)addAppAsLoginItem;
- (void)deleteAppFromLoginItem;
- (IBAction)setApplicationIsAgent:(id)sender;
- (BOOL)shouldBeUIElement;
- (void)setShouldBeUIElement:(BOOL)hidden;

- (void)updateNowPlaying;

@end
