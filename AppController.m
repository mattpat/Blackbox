//
//  AppController.m
//  Blackbox
//
//  Created by Matt Patenaude on 11/26/08.
//  Copyright 2008 Matt Patenaude. All rights reserved.
//

#import "AppController.h"
#import "BBServer.h"
#import "SampleResponder.h"


@implementation AppController

- (id)init
{
	if (self = [super init])
	{
		server = [[BBServer alloc] initWithPort:0 delegate:self];
		[server setResponder:[[[SampleResponder alloc] init] autorelease] forLocation:@"/hi/there"];
		BBDirectoryResponder *dirResponder = [BBDirectoryResponder directoryResponderWithDirectory:NSHomeDirectory()];
		//[dirResponder setAllowDirectoryListing:NO];
		[server setResponder:dirResponder forLocation:@"/matt"];
	}
	return self;
}
- (void)dealloc
{
	[server release];
	[super dealloc];
}
- (IBAction)startServer:(id)sender
{
	[server setPort:[portField intValue]];
	NSError *err;
	BOOL success = [server startWithError:&err];
	if (!success)
		NSLog(@"Error: %@", [err localizedDescription]);
	else
		NSLog(@"Running on port %d", [server port]);
}
- (IBAction)stopServer:(id)sender
{
	[server stop];
}

@end
