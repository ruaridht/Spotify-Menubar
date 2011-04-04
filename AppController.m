//
//  AppController.m
//  Spotify Menubar
//
//  Created by Ruaridh Thomson on 06/06/2010.
//  Copyright 2010 Life Up North/Ruaridh Thomson. All rights reserved.
//
//	This software is distributed under licence. Use of this software
//	implies agreement with all terms and conditions of the accompanying
//	software licence.

#import "AppController.h"
#import <sys/sysctl.h>

#include "GetPID.h"

#import <ShortcutRecorder/ShortcutRecorder.h>
#import <SDGlobalShortcuts/SDGlobalShortcuts.h>

typedef struct kinfo_proc kinfo_proc;

@implementation AppController

- (id) init
{	
    if (![super init])
    {
        return nil;
    }
	
	numberOfProcesses = -1; // means "not initialized"
	processList = NULL;
	processID = -1; // Means the process doesn't exist
	
	theSource = NULL;
	
	[NSApp setDelegate:self];
	queue = [[NSOperationQueue alloc] init];
	
	spotifyChecker = [NSTimer scheduledTimerWithTimeInterval:10.0 target: self selector: @selector(checkIsSpotifyActive) userInfo:nil repeats:YES];
	//[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"showMenubarIcon"];
    
	return self;
}

- (void)awakeFromNib
{
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"showMenubarIcon"]) {
		[self setStatusItem];
	}
	
	// Shortcut Recorders
	[playPauseRecorder setCanCaptureGlobalHotKeys:YES];
	[skipForwardRecorder setCanCaptureGlobalHotKeys:YES];
	[skipBackRecorder setCanCaptureGlobalHotKeys:YES];
	
	SDGlobalShortcutsController *shortcutsController = [SDGlobalShortcutsController sharedShortcutsController];
	[shortcutsController addShortcutFromDefaultsKey:@"ppGlobalHotkey"
										withControl:playPauseRecorder
											 target:self
										   selector:@selector(sendPlayPauseThreaded)];
	[shortcutsController addShortcutFromDefaultsKey:@"sfGlobalHotkey"
										withControl:skipForwardRecorder
											 target:self
										   selector:@selector(sendSkipForwardThreaded)];
	[shortcutsController addShortcutFromDefaultsKey:@"sbGlobalHotkey"
										withControl:skipBackRecorder
											 target:self
										   selector:@selector(sendSkipBackThreaded)];
	
	// Welcome Window
	if ([showWelcomeWindow state] == NSOffState) {
		[NSApp activateIgnoringOtherApps:YES];
		[welcomeWindow makeKeyAndOrderFront:self];
	}
	
	//[self checkSpotifyStatus];
	// Need to know if the user wants SM to open Spotify.  Or if the user is willing to open spotify themself.
	// NOTE: Add an 'Open Spotify' keybind and a 'Quit Spotify' keybind (?).
	[self checkIsSpotifyActive];
	
	if ([openSpotifyOnLaunch state]) {
		[[NSWorkspace sharedWorkspace] launchApplication:@"Spotify"];
	}
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"showMiniControls"]) {
		[self toggleMiniControls:nil];
	}
	
	// Setup the preferences window.
	[self loadView:generalView];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	NSLog(@"SM Launched");
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
	
}

- (void)dealloc
{
	[[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
	[super dealloc];
}

- (NSOperationQueue *)operationQueue
{
	return queue;
}

- (void)checkIsSpotifyActive
{
	if (![self isSpotifyActive]) {
		if ([[menubarIconStyle selectedItem] tag] == 1) {
			[statusItem setImage:[NSImage imageNamed:@"statusOff.png"]];
		} else {
			[statusItem setImage:[NSImage imageNamed:@"statusOffGrey.png"]];
		}
	} else {
		[statusItem setImage:[NSImage imageNamed:@"statusOn.png"]];
	}
}

- (BOOL)isSpotifyActive
{
	int procID = GetPIDForProcessName([@"Spotify" UTF8String]);
	
	if (procID == -1) {
		return NO;
	} else {
		return YES;
	}
}

#pragma mark -
#pragma mark IBActions

- (IBAction)switchMenubarIconStyle:(id)sender
{
	[self checkIsSpotifyActive];
}

- (IBAction)switchPreferenceView:(id)sender
{
	[prefToolbar setSelectedItemIdentifier:[sender itemIdentifier]];
	
	if ([sender tag] == 0) {
		[self loadView: generalView];
	} else if ([sender tag] == 1) {
		[self loadView: shortcutsView];
	} else if ([sender tag] == 2) {
		[self loadView: advancedView];
	} else if ([sender tag] == 3) {
		[self loadView: helpView];
	} else if ([sender tag] == 4) {
		[self loadView: aboutView];
	} else if ([sender tag] == 5) {
		[self loadView: simbleView];
	}
}

- (void)loadView:(NSView *)theView
{
	NSView *tempView = [[NSView alloc] initWithFrame: [[prefWindow contentView] frame]];
    [prefWindow setContentView: tempView];
    [tempView release];
	
	NSRect newFrame = [prefWindow frame];
    newFrame.size.height =	[theView frame].size.height + ([prefWindow frame].size.height - [[prefWindow contentView] frame].size.height); // Compensates for toolbar
    newFrame.size.width =	[theView frame].size.width;
    newFrame.origin.y +=	([[prefWindow contentView] frame].size.height - [theView frame].size.height); // Origin moves by difference in two views
    newFrame.origin.x +=	([[prefWindow contentView] frame].size.width - newFrame.size.width)/2; // Origin moves by difference in two views, halved to keep center alignment
    
	[prefWindow setFrame: newFrame display: YES animate: YES];
    [prefWindow setContentView: theView];
}

- (IBAction)openAboutWindow:(id)sender
{
	[self loadView:aboutView];
	[self openPreferences:self];
}

- (IBAction)openPreferences:(id)sender
{
	//[preferencesWindow makeKeyAndOrderFront:NULL];
	[NSApp activateIgnoringOtherApps:YES];
	[prefWindow makeKeyAndOrderFront:self];
}

- (IBAction)openSpotifyPreferences:(id)sender
{
	// Send the keystroke to open preferences
	[self pressHotkey:43 withModifier:NSCommandKeyMask];
	
	// Send the keystroke to bring Spotify to the front
	[self pressHotkey:18 withModifier:(NSCommandKeyMask | NSAlternateKeyMask)];
}

- (IBAction)resetKeybinds:(id)sender
{
	KeyCombo combo1 = { (NSShiftKeyMask | NSAlternateKeyMask), (CGKeyCode)49 };
	KeyCombo combo2 = { (NSShiftKeyMask | NSAlternateKeyMask), (CGKeyCode)124 };
	KeyCombo combo3 = { (NSShiftKeyMask | NSAlternateKeyMask), (CGKeyCode)123 };
	
	[playPauseRecorder setKeyCombo:combo1];
	[skipForwardRecorder setKeyCombo:combo2];
	[skipBackRecorder setKeyCombo:combo3];
}

- (IBAction)toggleOpenAtLogin:(id)sender
{
	if ([openAtLogin state]) {
		[self addAppAsLoginItem];
	} else {
		[self deleteAppFromLoginItem];
	}
}

- (IBAction)toggleMiniControls:(id)sender
{
	float width = 25.0;
	
	if ( !playItem ) {
		fwrdItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:width] retain];
		playItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:width] retain];
		backItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:width] retain];
		
		[playItem setImage:[NSImage imageNamed:@"mini-play-up"]];
		[playItem setAlternateImage:[NSImage imageNamed:@"mini-play-down"]];
		[playItem setHighlightMode:NO];
		[playItem setTarget:self];
		[playItem setAction:@selector(sendPlayPauseThreaded)];
		
		[fwrdItem setImage:[NSImage imageNamed:@"mini-fwrd-up"]];
		[fwrdItem setAlternateImage:[NSImage imageNamed:@"mini-fwrd-down"]];
		[fwrdItem setHighlightMode:NO];
		[fwrdItem setTarget:self];
		[fwrdItem setAction:@selector(sendSkipForwardThreaded)];
		
		[backItem setImage:[NSImage imageNamed:@"mini-back-up"]];
		[backItem setAlternateImage:[NSImage imageNamed:@"mini-back-down"]];
		[backItem setHighlightMode:NO];
		[backItem setTarget:self];
		[backItem setAction:@selector(sendSkipBackThreaded)];
		
	} else {
		[playItem release];
		playItem = nil;
		
		[fwrdItem release];
		fwrdItem = nil;
		
		[backItem release];
		backItem = nil;
	}
	
}

- (IBAction)checkForProcesses:(id)sender
{
	//NSString *processName = [textfield stringValue];
	
	//[self obtainFreshProcessList];
	
	//[self findProcessWithName:processName];
}

- (IBAction)findProcessesWithName:(id)sender
{
	NSString *processName = [textfield stringValue];
	
	int procID = GetPIDForProcessName([processName UTF8String]);
	
	if (procID == -1) {
		NSLog(@"%@ process not found: %i", processName, procID);
	} else {
		NSLog(@"%@ PID: %i", processName, procID);
		processID = procID;
	}
	
}

- (IBAction)sendPlayPause:(id)sender
{
	[self pressHotkey:49 withModifier:0];
	/*
	NSInvocationOperation* theOp = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(sendPlayPauseThreaded) object:nil];
	[[[NSApp delegate] operationQueue] addOperation:theOp];
	*/
}

- (IBAction)sendSkipForward:(id)sender
{
	[self pressHotkey:124 withModifier:NSCommandKeyMask];
	/*
	NSInvocationOperation* theOp = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(sendSkipForwardThreaded) object:nil];
	[[[NSApp delegate] operationQueue] addOperation:theOp];
	 */
}

- (IBAction)sendSkipBack:(id)sender
{
	[self pressHotkey:123 withModifier:NSCommandKeyMask];
	/*
	NSInvocationOperation* theOp = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(sendSkipBackThreaded) object:nil];
	[[[NSApp delegate] operationQueue] addOperation:theOp];
	 */
}

- (IBAction)sendKeystroke:(id)sender
{
	[self pressHotkey:49 withModifier:0];
}

- (IBAction)syncroniseUserDefaults:(id)sender
{
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)openURLLifeUpNorth:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://lifeupnorth.co.uk/lun/"]];
}

- (IBAction)sendLUNemail:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"mailto:lifeupnorth@me.com"]];
}

- (IBAction)openUrlSimbl:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.culater.net/software/SIMBL/SIMBL.php"]];
}

- (IBAction)openUrlLunPlugin:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://lifeupnorth.co.uk/lun/#5"]];
}

#pragma mark -
#pragma mark KeyEvents
- (void)sendPlayPauseHard
{
	usleep(200000);
	[self pressHotkey:49 withModifier:0];
}

- (void)sendPlayPauseThreaded
{
	NSInvocationOperation* theOp = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(sendPlayPauseHard) object:nil];
	[[[NSApp delegate] operationQueue] addOperation:theOp];
}

- (void)sendSkipForwardHard
{
	usleep(200000);
	[self pressHotkey:124 withModifier:NSCommandKeyMask];
}

- (void)sendSkipForwardThreaded
{
	NSInvocationOperation* theOp = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(sendSkipForwardHard) object:nil];
	[[[NSApp delegate] operationQueue] addOperation:theOp];
}

- (void)sendSkipBackHard
{
	usleep(200000);
	[self pressHotkey:123 withModifier:NSCommandKeyMask];
}

- (void)sendSkipBackThreaded
{
	NSInvocationOperation* theOp = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(sendSkipBackHard) object:nil];
	[[[NSApp delegate] operationQueue] addOperation:theOp];
}


// We should not really be using usleep() here. Rather use separate methods
// with [self performSelector: withObject: afterDelay:].
- (void)pressHotkey: (int)hotkey withModifier: (unsigned int)modifier
{
	if (![self isSpotifyActive]) {
		// If Spotify isn't open, we don't want to try and send it an event.
		
		// If the user wants Spotify to open, we'll do that now.
		if ([openSpotifyOnKeybind state]) {
			[[NSWorkspace sharedWorkspace] launchApplication:@"Spotify"];
		}
		return;
	}
	// Since we are receiving a hotkey at the same time?
	// This is weird, but understandable, since we want to send a keystroke at roughly the same time we press =[
	//usleep(100000);
	
    if((hotkey < 0) || (hotkey > 128)) return;
    //if(modifier < 0 || modifier > 3) return;
    
    unsigned int flags = modifier;
    ProcessSerialNumber spotPSN = [self getSpotifyProcessSerialNumber];
    if(spotPSN.lowLongOfPSN == kNoProcess && spotPSN.highLongOfPSN == kNoProcess) return;
    
    CGEventRef tempEvent = CGEventCreate(NULL);
    if(tempEvent) CFRelease(tempEvent);
    
    // create the key down.up
    CGEventRef keyDn = NULL, keyUp = NULL;
    
    // create our source
    CGEventSourceRef source = [self source];
	
    if (source) {
        
        // KLGetCurrentKeyboardLayout?
        // TISCopyCurrentKeyboardLayoutInputSource?
        
        keyDn = CGEventCreateKeyboardEvent(source, (CGKeyCode)hotkey, TRUE);
        keyUp = CGEventCreateKeyboardEvent(source, (CGKeyCode)hotkey, FALSE);
        
        // set flags for the event (does this even matter? No.)
        CGEventSetFlags(keyDn, modifier);
        CGEventSetFlags(keyUp, modifier);
        
        // hit any specified modifier keys
        if( flags & NSAlternateKeyMask)	{
            CGEventRef altKeyDn = CGEventCreateKeyboardEvent(source, (CGKeyCode)kVK_Option, TRUE);
            if(altKeyDn) {
                CGEventPostToPSN(&spotPSN, altKeyDn);
                CFRelease(altKeyDn);
                usleep(10000);
            }
        }
        if( flags & NSShiftKeyMask) {
            CGEventRef sftKeyDn = CGEventCreateKeyboardEvent(source, (CGKeyCode)kVK_Shift, TRUE);
            if(sftKeyDn) {
                CGEventPostToPSN(&spotPSN, sftKeyDn);
                CFRelease(sftKeyDn);
                usleep(10000);
            }
        }
        if( flags & NSControlKeyMask) {
            CGEventRef ctlKeyDn = CGEventCreateKeyboardEvent(source, (CGKeyCode)kVK_Control, TRUE);
            if(ctlKeyDn) {
                CGEventPostToPSN(&spotPSN, ctlKeyDn);
                CFRelease(ctlKeyDn);
                usleep(10000);
            }
        }
		if ( flags & NSCommandKeyMask) {
			CGEventRef cmdKeyDn = CGEventCreateKeyboardEvent(source, (CGKeyCode)kVK_Command, TRUE);
            if(cmdKeyDn) {
                CGEventPostToPSN(&spotPSN, cmdKeyDn);
                CFRelease(cmdKeyDn);
                usleep(10000);
            }
		}
        
        // post the actual event
        CGEventPostToPSN(&spotPSN, keyDn);
        usleep(30000);
        CGEventPostToPSN(&spotPSN, keyUp);
        usleep(10000);
        
        // undo the modifier keys
        if( flags & NSControlKeyMask) {
            CGEventRef ctlKeyUp = CGEventCreateKeyboardEvent(source, (CGKeyCode)kVK_Control, FALSE);
            if(ctlKeyUp) {
                CGEventPostToPSN(&spotPSN, ctlKeyUp);
                CFRelease(ctlKeyUp);
                usleep(10000);
            }
        }
        if( flags & NSShiftKeyMask) {
            CGEventRef sftKeyUp = CGEventCreateKeyboardEvent(source, (CGKeyCode)kVK_Shift, false);
            if(sftKeyUp) {
                CGEventPostToPSN(&spotPSN, sftKeyUp);
                CFRelease(sftKeyUp);
                usleep(10000);
            }
        }
        if( flags & NSAlternateKeyMask) {
            CGEventRef altKeyUp = CGEventCreateKeyboardEvent(source, (CGKeyCode)kVK_Option, FALSE);
            if(altKeyUp) {
                CGEventPostToPSN(&spotPSN, altKeyUp);
                CFRelease(altKeyUp);
                usleep(10000);
            }
        }
		if( flags & NSCommandKeyMask) {
            CGEventRef cmdKeyUp = CGEventCreateKeyboardEvent(source, (CGKeyCode)kVK_Command, FALSE);
            if(cmdKeyUp) {
                CGEventPostToPSN(&spotPSN, cmdKeyUp);
                CFRelease(cmdKeyUp);
                usleep(10000);
            }
        }
        
        if(keyDn)  CFRelease(keyDn);
        if(keyUp)  CFRelease(keyUp);
        // CFRelease(source);
    } else {
        // We can't post the event.  Notify the user?
    }
}

- (CGEventSourceRef)source
{
    if(theSource == NULL) {
        theSource = CGEventSourceCreate(kCGEventSourceStateHIDSystemState);  
        if(theSource) {
            //CGEventSourceSetKeyboardType(theSource, LMGetKbdType());
			CGEventSourceSetKeyboardType(theSource, kCGAnyInputEventType);
            CGEventSourceSetLocalEventsSuppressionInterval(theSource, 0.0);
            CGEventSourceSetLocalEventsFilterDuringSuppressionState(theSource, kCGEventFilterMaskPermitLocalMouseEvents, kCGEventSuppressionStateSuppressionInterval);
        }
    }
    return theSource;
}

#pragma mark -
#pragma mark Process Methods

- (int)numberOfProcesses
{
    return numberOfProcesses;
}

- (void)setNumberOfProcesses:(int)num
{
    numberOfProcesses = num;
}

- (int)getBSDProcessList:(kinfo_proc **)procList
   withNumberOfProcesses:(size_t *)procCount
{
    int             err;
    kinfo_proc *    result;
    bool            done;
    static const int    name[] = { CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0 };
    size_t          length;
	
    // a valid pointer procList holder should be passed
    assert( procList != NULL );
    // But it should not be pre-allocated
    assert( *procList == NULL );
    // a valid pointer to procCount should be passed
    assert( procCount != NULL );
	
    *procCount = 0;
	
    result = NULL;
    done = false;
	
    do
    {
        assert( result == NULL );
		
        // Call sysctl with a NULL buffer to get proper length
        length = 0;
        err = sysctl((int *)name,(sizeof(name)/sizeof(*name))-1,NULL,&length,NULL,0);
        if( err == -1 )
            err = errno;
		
        // Now, proper length is optained
        if( err == 0 )
        {
            result = malloc(length);
            if( result == NULL )
                err = ENOMEM;   // not allocated
        }
		
        if( err == 0 )
        {
            err = sysctl( (int *)name, (sizeof(name)/sizeof(*name))-1, result, &length, NULL, 0);
            if( err == -1 )
                err = errno;
			
            if( err == 0 )
                done = true;
            else if( err == ENOMEM )
            {
                assert( result != NULL );
                free( result );
                result = NULL;
                err = 0;
            }
        }
    }while ( err == 0 && !done );
	
    // Clean up and establish post condition
    if( err != 0 && result != NULL )
    {
        free(result);
        result = NULL;
    }
	
    *procList = result; // will return the result as procList
    if( err == 0 )
        *procCount = length / sizeof( kinfo_proc );
	
    assert( (err == 0) == (*procList != NULL ) );
	
    return err;
}

- (void)obtainFreshProcessList
{
    int i;
    kinfo_proc *allProcs = 0;
    size_t numProcs;
    NSString *procName;
	NSString *procID;
	
    int err =  [self getBSDProcessList:&allProcs withNumberOfProcesses:&numProcs];
    if( err )
    {
        numberOfProcesses = -1;
        processList = NULL;
		
        return;
    }
	
    // Construct an array for ( process name )
    processList = [NSMutableArray arrayWithCapacity:numProcs];
	NSLog(@"Number of processes: %i", numProcs);
    for( i = 0; i < numProcs; i++ )
    {
        procName = [NSString stringWithFormat:@"%s", allProcs[i].kp_proc.p_comm];
		procID = [NSString stringWithFormat:@"%s", allProcs[i].kp_proc.p_pid];
        [processList addObject:procName];
		NSLog(@"Process %i : %@", i, procName);
		NSLog(@"With PID: %@", procID);
		NSLog(@"----------------------------------------");
    }
	
    [self setNumberOfProcesses:numProcs];
	
    // NSLog(@"# of elements = %d total # of process = %d\n",
    //         [processArray count], numProcs );
	
    free( allProcs );
	
}

- (BOOL)findProcessWithName:(NSString *)procNameToSearch
{
    int index;
	
    index = [processList indexOfObject:procNameToSearch];
	
    if( index == -1 ) {
		NSLog(@"Process not found");
        return NO;
    } else {
		NSLog(@"Process found");
        return YES;
	}
}

- (ProcessSerialNumber)getSpotifyProcessSerialNumber
{
	ProcessSerialNumber pSN = {kNoProcess, kNoProcess};
	pid_t spotPID = 0;
    for(NSDictionary *processDict in [[NSWorkspace sharedWorkspace] launchedApplications]) {
		if( [[processDict objectForKey: @"NSApplicationBundleIdentifier"] isEqualToString: @"com.spotify.client"] ) {
			pSN.highLongOfPSN = [[processDict objectForKey: @"NSApplicationProcessSerialNumberHigh"] longValue];
			pSN.lowLongOfPSN  = [[processDict objectForKey: @"NSApplicationProcessSerialNumberLow"] longValue];
			
			OSStatus err = GetProcessPID(&pSN, &spotPID);
			_lastAttachedPID = spotPID;
			
			if( err == noErr && spotPID > 0 && spotPID == _selectedPID) {
				return pSN;
			}
		}
	}
	
	return pSN;
}

// Left in as a source of information
/*
#pragma mark -
#pragma mark Alternate Methods

static int GetBSDProcessList(kinfo_proc **procList, size_t *procCount)
// Returns a list of all BSD processes on the system.  This routine
// allocates the list and puts it in *procList and a count of the
// number of entries in *procCount.  You are responsible for freeing
// this list (use "free" from System framework).
// On success, the function returns 0.
// On error, the function returns a BSD errno value.
{
    int                 err;
    kinfo_proc *        result;
    bool                done;
    static const int    name[] = { CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0 };
    // Declaring name as const requires us to cast it when passing it to
    // sysctl because the prototype doesn't include the const modifier.
    size_t              length;
	
    assert( procList != NULL);
    assert(*procList == NULL);
    assert(procCount != NULL);
	
    *procCount = 0;
	
    // We start by calling sysctl with result == NULL and length == 0.
    // That will succeed, and set length to the appropriate length.
    // We then allocate a buffer of that size and call sysctl again
    // with that buffer.  If that succeeds, we're done.  If that fails
    // with ENOMEM, we have to throw away our buffer and loop.  Note
    // that the loop causes use to call sysctl with NULL again; this
    // is necessary because the ENOMEM failure case sets length to
    // the amount of data returned, not the amount of data that
    // could have been returned.
	
    result = NULL;
    done = false;
    do {
        assert(result == NULL);
		
        // Call sysctl with a NULL buffer.
		
        length = 0;
        err = sysctl( (int *) name, (sizeof(name) / sizeof(*name)) - 1,
					 NULL, &length,
					 NULL, 0);
        if (err == -1) {
            err = errno;
        }
		
        // Allocate an appropriately sized buffer based on the results
        // from the previous call.
		
        if (err == 0) {
            result = malloc(length);
            if (result == NULL) {
                err = ENOMEM;
            }
        }
		
        // Call sysctl again with the new buffer.  If we get an ENOMEM
        // error, toss away our buffer and start again.
		
        if (err == 0) {
            err = sysctl( (int *) name, (sizeof(name) / sizeof(*name)) - 1,
						 result, &length,
						 NULL, 0);
            if (err == -1) {
                err = errno;
            }
            if (err == 0) {
                done = true;
            } else if (err == ENOMEM) {
                assert(result != NULL);
                free(result);
                result = NULL;
                err = 0;
            }
        }
    } while (err == 0 && ! done);
	
    // Clean up and establish post conditions.
	
    if (err != 0 && result != NULL) {
        free(result);
        result = NULL;
    }
    *procList = result;
    if (err == 0) {
        *procCount = length / sizeof(kinfo_proc);
    }
	
    assert( (err == 0) == (*procList != NULL) );
	
    return err;
}
*/

#pragma mark -
#pragma mark Login Methods

-(void) addAppAsLoginItem
{
	NSString * appPath = [[NSBundle mainBundle] bundlePath];
	
	// This will retrieve the path for the application
	// For example, /Applications/test.app
	CFURLRef url = (CFURLRef)[NSURL fileURLWithPath:appPath]; 
	
	// Create a reference to the shared file list.
	// We are adding it to the current user only.
	// If we want to add it all users, use
	// kLSSharedFileListGlobalLoginItems instead of
	//kLSSharedFileListSessionLoginItems
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL,
															kLSSharedFileListSessionLoginItems, NULL);
	if (loginItems) {
		//Insert an item to the list.
		LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(loginItems,
																	 kLSSharedFileListItemLast, NULL, NULL,
																	 url, NULL, NULL);
		if (item){
			CFRelease(item);
		}
	}	
	
	CFRelease(loginItems);
}

-(void) deleteAppFromLoginItem
{
	NSString * appPath = [[NSBundle mainBundle] bundlePath];
	
	// This will retrieve the path for the application
	// For example, /Applications/test.app
	CFURLRef url = (CFURLRef)[NSURL fileURLWithPath:appPath]; 
	
	// Create a reference to the shared file list.
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL,
															kLSSharedFileListSessionLoginItems, NULL);
	
	if (loginItems) {
		UInt32 seedValue;
		//Retrieve the list of Login Items and cast them to
		// a NSArray so that it will be easier to iterate.
		NSArray  *loginItemsArray = (NSArray *)LSSharedFileListCopySnapshot(loginItems, &seedValue);
		int i = 0;
		for(i ; i< [loginItemsArray count]; i++){
			LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)[loginItemsArray
																		objectAtIndex:i];
			//Resolve the item with URL
			if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*) &url, NULL) == noErr) {
				NSString * urlPath = [(NSURL*)url path];
				if ([urlPath compare:appPath] == NSOrderedSame){
					LSSharedFileListItemRemove(loginItems,itemRef);
				}
			}
		}
		[loginItemsArray release];
	}
}

#pragma mark -
#pragma mark Preferences

- (void)setStatusItem
{
	// Create an NSStatusItem.
	float width = 25.0;
	statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:width] retain];
	[statusItem setMenu:statusMenu];
	[statusItem setImage:[NSImage imageNamed:@"statusOffGrey.png"]];
	[statusItem setAlternateImage:[NSImage imageNamed:@"statusHighlight.png"]];
	[statusItem setHighlightMode:YES];
	
}

- (IBAction)setApplicationIsAgent:(id)sender
{
	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"runAsUIAgent"]) {
		//NSLog(@"Show Dock Icon");
		[self setShouldBeUIElement:NO];
		[showMenubarIcon setEnabled:YES];
	} else {
		//NSLog(@"Hide Dock Icon");
		[self setShouldBeUIElement:YES];
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"showMenubarIcon"];
		[showMenubarIcon setEnabled:NO];
		[showMenubarIcon setState:1];
	}
}

- (BOOL)shouldBeUIElement
{
	return [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"LSUIElement"] boolValue];
}

- (void)setShouldBeUIElement:(BOOL)hidden
{
	NSString * plistPath = nil;
	NSFileManager *manager = [NSFileManager defaultManager];
	if (plistPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents/Info.plist"]) {
		if ([manager isWritableFileAtPath:plistPath]) {
			NSMutableDictionary *infoDict = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
			[infoDict setObject:[NSNumber numberWithBool:hidden] forKey:@"LSUIElement"];
			[infoDict writeToFile:plistPath atomically:NO];
			[manager setAttributes:[NSDictionary dictionaryWithObject:[NSDate date] forKey:NSFileModificationDate] ofItemAtPath:[[NSBundle mainBundle] bundlePath] error:nil];
		}
	}
}

@end
