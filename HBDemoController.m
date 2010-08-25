//
//  HBDemoController.m
//  Blackbox
//
//  Created by Matt Patenaude on 8/24/10.
//  Copyright 2010 Matt Patenaude. All rights reserved.
//

#import "HBDemoController.h"
#import "BBRequest.h"


@implementation HBDemoController

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
		
		// create an array to handle open connections
		openConnections = [[NSMutableArray alloc] init];
		connectionNames = [[NSMutableArray alloc] init];
	}
	return self;
}
- (void)awakeFromNib
{
	// finally, we set our HaleBopp responder to respond to
	// the path "/poll"
	[server setResponder:haleBoppResponder forPath:@"/poll"];
}

#pragma mark Deallocator
- (void)dealloc
{
	[server release];
	[openConnections release];
	[connectionNames release];
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
- (IBAction)pushStringToSelectedConnection:(id)sender
{
	// this pushes the string to the selected connection
	NSInteger selection = [connectionTable selectedRow];
	if (selection > -1)
		[haleBoppResponder pushResponseString:[pushStringField stringValue] toRequestWithIdentifier:[openConnections objectAtIndex:selection]];
}

#pragma mark Responder methods (BBResponder)
- (void)handleRequest:(BBRequest *)theRequest
{
	// We get here if someone tried to access a URL we
	// don't have a responder setup for (because this object is
	// set as the "default responder")
	
	// If they try to access "/comet", we'll put up our sample
	// HTML file, which calls "/poll" to test the Comet server
	if ([[theRequest fullPath] isEqualToString:@"/comet"])
		[theRequest respondWithFile:[[NSBundle mainBundle] pathForResource:@"comet" ofType:@"html"]];
	else
	{
		// We'll return a 404, put up an error message, and
		// print out the URL the user tried to access to the Console
		[theRequest setResponseStatusCode:404];
		[theRequest setResponseContentType:@"text/html"];
		[theRequest setResponseString:@"<h1>404 File Not Found</h1><p>Perhaps you were looking for <a href=\"/comet\">the Comet demo</a>?</p>"];
		
		NSLog(@"Request: someone tried to access %@", [theRequest fullPath]);
	}
}

#pragma mark HaleBopp delegate methods (HBResponderDelegate)
- (void)startedLongPollWithRequest:(BBRequest *)theRequest identifier:(NSString *)theIdentifier
{
	[openConnections addObject:theIdentifier];
	
	// add a name if one is passed as a param
	// otherwise, just use the identifier
	NSString *name = [[theRequest GETParameters] objectForKey:@"name"];
	[connectionNames addObject:((name) ? name : theIdentifier)];
	
	[connectionTable reloadData];
}
- (void)requestNoLongerAvailableWithIdentifier:(NSString *)theIdentifier
{
	NSInteger idx = [openConnections indexOfObject:theIdentifier];
	[openConnections removeObjectAtIndex:idx];
	[connectionNames removeObjectAtIndex:idx];
	[connectionTable reloadData];
}

#pragma mark Table data source methods
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [openConnections count];
}
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	return [connectionNames objectAtIndex:rowIndex];
}

@end
