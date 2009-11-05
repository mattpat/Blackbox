//
//  BBConnection.m
//  Blackbox
//
//  Created by Matt Patenaude on 11/26/08.
//  Copyright 2008 Matt Patenaude. All rights reserved.
//

#import "BBConnection.h"
#import "BBServer.h"
#import "BBRequest.h"
#import "AsyncSocket.h"


@implementation BBConnection

#pragma mark Initializers
- (id)initWithSocket:(AsyncSocket *)newSocket delegate:(id)newDelegate
{
	if (self = [super init])
	{
		socket = [newSocket retain];
		[socket setDelegate:self];
		
		if (newDelegate != nil)
			delegate = [newDelegate retain];
		message = NULL;
		isMessageComplete = YES;
		
		[socket readDataToData:[AsyncSocket CRLFData] withTimeout:READ_TIMEOUT tag:HTTP_REQUEST];
	}
	return self;
}

#pragma mark Deallocator
- (void)dealloc
{
	if (message)
		CFRelease(message);
	if (delegate != nil)
		[delegate release];
	[socket release];
	[super dealloc];
}

#pragma mark Properties
- (id)delegate
{
	return delegate;
}
- (void)setDelegate:(id)newDelegate
{
	if (delegate != nil)
	{
		[delegate release];
		delegate = nil;
	}
	delegate = [newDelegate retain];
}
- (AsyncSocket *)socket
{
	return socket;
}

#pragma mark AsyncSocket delegate methods
- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData*)data withTag:(long)tag
{
	if (isMessageComplete)
		message = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, TRUE);
	
	BOOL success = CFHTTPMessageAppendBytes(message, [data bytes], [data length]);
	if (success)
	{
		if (CFHTTPMessageIsHeaderComplete(message))
		{
			isMessageComplete = YES;
			
			BBRequest *theRequest = [[BBRequest alloc] initWithServer:delegate connection:self message:message];
			[delegate _newRequest:theRequest connection:self];
			[theRequest release];
			
			CFRelease(message);
			message = NULL;
		}
		else
		{
			isMessageComplete = NO;
			[socket readDataToData:[AsyncSocket CRLFData] withTimeout:READ_TIMEOUT tag:HTTP_REQUEST];
		}
	}
	else
	{
		NSLog(@"Incoming message not a HTTP header, ignored.");
		//[delegate _closeConnection:self];
	}
}
- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag
{
	if (tag == HTTP_RESPONSE)
	{
		// Release the old request, and create a new one
		if (message)
			CFRelease(message);
		message = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, YES);
		
		// And start listening for more requests
		[socket readDataToData:[AsyncSocket CRLFData] withTimeout:READ_TIMEOUT tag:HTTP_REQUEST];
	}
}
- (void)onSocketDidDisconnect:(AsyncSocket *)sock
{
	[[NSNotificationCenter defaultCenter] postNotificationName:HTTPConnectionDidDieNotification object:self];
}

@end
