//
//  HBDemoController.h
//  Blackbox
//
//  Created by Matt Patenaude on 8/24/10.
//  Copyright 2010 Matt Patenaude. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BBServer.h"
#import "BBResponder.h"
#import "HBResponder.h"
#import "HBResponderDelegate.h"


// Constants
#define BBDemoServerDefaultPort 8080

@interface HBDemoController : NSObject<BBResponder,HBResponderDelegate> {
	BBServer *server;
	BOOL serverIsRunning;
	NSMutableArray *openConnections;
	NSMutableArray *connectionNames;
	
	IBOutlet NSImageView *statusImageView;
	IBOutlet NSTextField *statusField;
	IBOutlet NSTextField *pushStringField;
	
	// Our other responder
	IBOutlet HBResponder *haleBoppResponder;
	
	// Request table view
	IBOutlet NSTableView *connectionTable;
}

// Application delegate methods
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication;

// Control methods
- (IBAction)startStopServer:(id)sender;
- (IBAction)pushStringToSelectedConnection:(id)sender;

// Responder methods (BBResponder)
- (void)handleRequest:(BBRequest *)theRequest;

// HaleBopp delegate methods (HBResponderDelegate)
- (void)startedLongPollWithRequest:(BBRequest *)theRequest identifier:(NSString *)theIdentifier;
- (void)requestNoLongerAvailableWithIdentifier:(NSString *)theIdentifier;

// Table data source methods
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex;

@end
