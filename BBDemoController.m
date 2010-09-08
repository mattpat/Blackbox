//
//  BBDemoController.m
//  Blackbox
//
//  Created by Matt Patenaude on 3/15/10.
//  Copyright 2010 Matt Patenaude. All rights reserved.
//

#import "BBDemoController.h"
#import "BBRequest.h"
#import "BBDemoLiveResponder.h"
#import <SystemConfiguration/SystemConfiguration.h>


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
- (void)awakeFromNib
{
	// get computer name
	NSString *computerName = (NSString *)SCDynamicStoreCopyComputerName(NULL, NULL);
	
	// setup our default (placeholder) values in the UI
	[[serverPortField cell] setPlaceholderString:[NSString stringWithFormat:@"%u", BBDemoServerDefaultPort]];
	[[bonjourNameField cell] setPlaceholderString:computerName];
	CFRelease((CFStringRef)computerName);
	
	// finally, we set our "live responder" to respond to
	// the path "/textbox"
	[server setResponder:textBoxResponder forPath:@"/textbox"];
	
	// if we're on 10.6, we can also use blocks!
	// visit "/blocks" to see an example
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6
	[server setHandlerForPath:@"/blocks" handler:^(BBRequest *theRequest){
		[theRequest setResponseContentType:@"text/html"];
		[theRequest setResponseString:@"<h1>Blocks Demo</h1><p>This response was returned using a block.</p>"];
	}];
#endif
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
		// let's configure the server first
		// first, the port
		[server setPort:BBDemoServerDefaultPort];
		NSString *portString = [serverPortField stringValue];
		if (![portString isEqualToString:@""])
			[server setPort:[portString integerValue]];
		
		// next, the Bonjour service
		[server setName:@""];
		[server setType:nil];
		
		if ([publishBonjourService state] == NSOnState)
		{
			NSString *bonjourName = [bonjourNameField stringValue];
			NSString *serviceType = [bonjourTypeField stringValue];
			if (![bonjourName isEqualToString:@""])
				[server setName:bonjourName];
			
			if (![serviceType isEqualToString:@""])
				[server setType:serviceType];
			else
				[server setType:@"_http._tcp."];
		}
		
		// now, we start the server
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
	[theRequest setResponseString:@"<h1>404 File Not Found</h1><p>Perhaps you were looking for <a href=\"/textbox\">the live textbox demo</a>?</p>"];
	
	NSLog(@"Request: someone tried to access %@", [theRequest fullPath]);
}

@end
