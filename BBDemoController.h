//
//  BBDemoController.h
//  Blackbox
//
//  Created by Matt Patenaude on 3/15/10.
//  Copyright 2010 Matt Patenaude. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BBServer.h"
#import "BBResponder.h"


// Constants
#define BBDemoServerDefaultPort 8080

// Forward declarations
@class BBDemoLiveResponder;

@interface BBDemoController : NSObject<BBResponder> {
	BBServer *server;
	BOOL serverIsRunning;
	
	IBOutlet NSImageView *statusImageView;
	IBOutlet NSTextField *statusField;
	
	IBOutlet NSTextField *serverPortField;
	IBOutlet NSButton *publishBonjourService;
	IBOutlet NSTextField *bonjourNameField;
	IBOutlet NSTextField *bonjourTypeField;
	
	// Our other responder
	IBOutlet BBDemoLiveResponder *textBoxResponder;
}

// Application delegate methods
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication;

// Control methods
- (IBAction)startStopServer:(id)sender;

// Responder methods (BBResponder)
- (void)handleRequest:(BBRequest *)theRequest;

@end
