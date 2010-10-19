//
//  HBCDemoController.h
//  Blackbox
//
//  Created by Matt Patenaude on 10/19/10.
//  Copyright 2010 Matt Patenaude. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BBServer.h"
#import "BBResponder.h"
#import "HBResponder.h"
#import "HBResponderDelegate.h"


// Constants
#define BBDemoServerDefaultPort 8080

@interface HBCDemoController : NSObject<HBResponderDelegate> {
	BBServer *server;
	BOOL serverIsRunning;
	NSMutableArray *openChannels;
	
	IBOutlet NSImageView *statusImageView;
	IBOutlet NSTextField *statusField;
	IBOutlet NSTextField *pushStringField;
	
	// Our other responder
	IBOutlet HBResponder *haleBoppResponder;
	
	// Channel table view
	IBOutlet NSTableView *channelTable;
}

// Application delegate methods
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication;

// Control methods
- (IBAction)startStopServer:(id)sender;
- (IBAction)pushStringToSelectedChannel:(id)sender;

// Channel management methods
- (IBAction)addChannel:(id)sender;
- (IBAction)removeChannel:(id)sender;

// Table data source methods
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex;
- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex;

@end
