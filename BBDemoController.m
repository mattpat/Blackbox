//
//  BBDemoController.m
//  Blackbox
//
//  Created by Matt Patenaude on 3/15/10.
//  Copyright 2010 Matt Patenaude. All rights reserved.
//

#import "BBDemoController.h"
#import "BBRequest.h"


@implementation BBDemoController

#pragma mark Initializers
- (id)init
{
	if (self = [super init])
	{
		// let's create our server
		server = [[BBServer alloc] init];
		
		// we'll set ourself as both the delegate,
		// and the default handler of HTTP requests
		[server setDelegate:self];
		[server setDefaultResponder:self];
		
		// we'll also set a default port; if we
		// don't do this, a random one will be chosen
		// the default port is specified in BBDemoController.h
		[server setPort:BBDemoServerDefaultPort];
		
		serverIsRunning = NO;
	}
	return self;
}

#pragma mark Deallocator
- (void)dealloc
{
	[server release];
	[super dealloc];
}

#pragma mark Application delegate methods
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return YES;
}

#pragma mark Control methods
- (IBAction)startStopServer:(id)sender
{
	if (!serverIsRunning)
	{
		NSError *err;
		if ([server start:&err])
		{
			[statusImageView setImage:[NSImage imageNamed:@"on"]];
			[statusField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Running On Port %u…", nil), [server port]]];
			serverIsRunning = YES;
		}
		else
		{
			[statusImageView setImage:[NSImage imageNamed:@"off"]];
			[statusField setStringValue:NSLocalizedString(@"Could Not Start Server", nil)];
			serverIsRunning = NO;
			NSLog(@"Error starting server: %@", [err localizedDescription]);
		}
	}
	else
	{
		[server stop];
		[statusImageView setImage:[NSImage imageNamed:@"off"]];
		[statusField setStringValue:NSLocalizedString(@"Not Running", nil)];
		serverIsRunning = NO;
	}
}

#pragma mark Responder methods (BBResponder)
- (void)handleRequest:(BBRequest *)theRequest
{
	// We get here if someone tried to access a URL we
	// don't have a responder setup for (because this object is
	// set as the "default responder")
	
	// We'll return a 404, put up an error message, and
	// print out the URL the user tried to access to the Console
	[theRequest setResponseStatusCode:404];
	[theRequest setResponseContentType:@"text/html"];
	[theRequest setResponseString:@"<h1>404 File Not Found</h1>"];
	
	NSLog(@"Request: someone tried to access %@", [theRequest fullPath]);
}

@end
