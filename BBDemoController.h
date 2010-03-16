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

@interface BBDemoController : NSObject<BBResponder> {
	BBServer *server;
	BOOL serverIsRunning;
	
	IBOutlet NSImageView *statusImageView;
	IBOutlet NSTextField *statusField;
}

// Application delegate methods
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication;

// Control methods
- (IBAction)startStopServer:(id)sender;

// Responder methods (BBResponder)
- (void)handleRequest:(BBRequest *)theRequest;

@end
