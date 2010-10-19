//
//  HBCDemoController.m
//  Blackbox
//
//  Created by Matt Patenaude on 10/19/10.
//  Copyright 2010 Matt Patenaude. All rights reserved.
//

#import "HBCDemoController.h"
#import "BBRequest.h"


@implementation HBCDemoController

#pragma mark Initializers
- (id)init
{
	if (self = [super init])
	{
		// let's create our server
		server = [[BBServer alloc] init];
		
		// we'll set ourself as the delegate,
		[server setDelegate:self];
		
		// we'll also set a default port; if we
		// don't do this, a random one will be chosen
		// the default port is specified in BBDemoController.h
		[server setPort:BBDemoServerDefaultPort];
		
		serverIsRunning = NO;
		
		// create an array to handle open channels
		openChannels = [[NSMutableArray alloc] init];
	}
	return self;
}
- (void)awakeFromNib
{
	// finally, we set our HaleBopp responder as our default
	[server setDefaultResponder:haleBoppResponder];
}

#pragma mark Deallocator
- (void)dealloc
{
	[server release];
	[openChannels release];
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
- (IBAction)pushStringToSelectedChannel:(id)sender
{
	// this pushes the string to the selected channel
	NSInteger selection = [channelTable selectedRow];
	if (selection > -1)
	{
		NSString *channelName = [openChannels objectAtIndex:selection];
		[haleBoppResponder pushString:[pushStringField stringValue] toChannel:channelName];
	}
}

#pragma mark HaleBopp responder delegate methods
- (BOOL)responder:(HBResponder *)responder allowConnectionToNonexistentChannelWithRequest:(BBRequest *)theRequest
{
	return NO;
}

#pragma mark Channel management methods
- (IBAction)addChannel:(id)sender
{
	[openChannels addObject:@"new-channel"];
	[haleBoppResponder createChannel:@"new-channel"];
	[channelTable reloadData];
}
- (IBAction)removeChannel:(id)sender
{
	NSInteger selection = [channelTable selectedRow];
	if (selection > -1)
	{
		NSString *channelName = [openChannels objectAtIndex:selection];
		[haleBoppResponder destroyChannel:channelName];
		
		[openChannels removeObjectAtIndex:selection];
		[channelTable reloadData];
	}
}

#pragma mark Table data source methods
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [openChannels count];
}
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	return [openChannels objectAtIndex:rowIndex];
}
- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	[haleBoppResponder destroyChannel:[openChannels objectAtIndex:rowIndex]];
	[openChannels replaceObjectAtIndex:rowIndex withObject:anObject];
	[haleBoppResponder createChannel:anObject];
}

@end
