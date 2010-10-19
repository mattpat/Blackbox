//
//  HBResponder.m
//  HaleBopp
//
//  Created by Matt Patenaude on 8/24/10.
//  Copyright 2010 Matt Patenaude.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "HBResponder.h"
#import "HBResponderDelegate.h"
#import "BBConnection.h"
#import "BBRequest.h"
#import <CommonCrypto/CommonDigest.h>


NSString *HBHexStringFromBytes(void *bytes, NSUInteger len);
NSString *HBHexStringFromBytes(void *bytes, NSUInteger len)
{
	NSMutableString *output = [NSMutableString string];
	
	unsigned char *input = (unsigned char *)bytes;
	
	NSUInteger i;
	for (i = 0; i < len; i++)
		[output appendFormat:@"%02x", input[i]];
	return output;
}

@interface NSString(HBAdditions)
- (NSString *)HBSHA1Hash;
@end

@implementation NSString(HBAdditions)
- (NSString *)HBSHA1Hash
{
	const char *input = [self UTF8String];
	unsigned char result[CC_SHA1_DIGEST_LENGTH];
	CC_SHA1(input, strlen(input), result);
	return HBHexStringFromBytes(result, CC_SHA1_DIGEST_LENGTH);
}
@end


@interface HBResponder()

// Low-level polling methods
- (NSString *)beginLongPollWithRequest:(BBRequest *)theRequest;

// Request fulfillment handlers
- (void)killRequestWithIdentifier:(NSString *)theIdentifier;
- (void)removeRequestWithIdentifier:(NSString *)theIdentifier;
- (void)connectionDied:(NSNotification *)theNotification;

// Responder methods (BBResponder)
- (void)handleRequest:(BBRequest *)theRequest;
- (BOOL)repliesAsynchronously;

@end


@implementation HBResponder

#pragma mark Initializers
- (id)init
{
	if (self = [super init])
	{
		openRequestIDs = [[NSMutableArray alloc] init];
		requests = [[NSMutableDictionary alloc] init];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionDied:) name:HTTPConnectionDidDieNotification object:nil];
		
		openChannels = [[NSMutableSet alloc] init];
		channelToRequestMap = [[NSMutableDictionary alloc] init];
	}
	return self;
}

#pragma mark Deallocator
- (void)dealloc
{
	[openRequestIDs release];
	[requests release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[openChannels release];
	[channelToRequestMap release];
	[super dealloc];
}

#pragma mark Properties
@synthesize delegate;

#pragma mark High-level client methods
- (BOOL)createChannel:(NSString *)channelName
{
	[openChannels addObject:channelName];
	
	NSMutableArray *channelRequests = [channelToRequestMap objectForKey:channelName];
	if (!channelRequests)
		[channelToRequestMap setObject:[NSMutableArray array] forKey:channelName];
	
	return YES;
}
- (BOOL)destroyChannel:(NSString *)channelName
{
	[openChannels removeObject:channelName];
	
	NSMutableArray *channelRequests = [channelToRequestMap objectForKey:channelName];
	if (channelRequests)
	{
		for (NSString *requestID in channelRequests)
			[self killRequestWithIdentifier:requestID];
		
		[channelToRequestMap removeObjectForKey:channelName];
	}
	
	return YES;
}
- (BOOL)pushString:(NSString *)theString toChannel:(NSString *)theChannel
{
	return [self pushString:theString contentType:@"text/plain" toChannel:theChannel];
}
- (BOOL)pushString:(NSString *)theString contentType:(NSString *)type toChannel:(NSString *)theChannel
{
	return [self pushData:[theString dataUsingEncoding:NSUTF8StringEncoding] contentType:type headers:nil toChannel:theChannel];
}
- (BOOL)pushPropertyList:(id)thePlist toChannel:(NSString *)theChannel
{
	NSString *err = nil;
	NSData *plist = [NSPropertyListSerialization dataFromPropertyList:thePlist format:NSPropertyListXMLFormat_v1_0 errorDescription:&err];
	
	if (err)
		[err release];
	
	return [self pushData:plist contentType:@"application/xml" headers:[NSDictionary dictionaryWithObject:@"true" forKey:@"X-PropertyList"] toChannel:theChannel];
}
- (BOOL)pushData:(NSData *)theData contentType:(NSString *)type headers:(NSDictionary *)headers toChannel:(NSString *)theChannel
{
	if (![openChannels containsObject:theChannel])
		return NO;
	
	NSMutableArray *requestList = [channelToRequestMap objectForKey:theChannel];
	NSArray *iterableRequests = [requestList copy];
	for (NSString *requestID in iterableRequests)
	{
		[self pushResponse:theData toRequestWithIdentifier:requestID contentType:type headers:headers statusCode:200];
		[requestList removeObject:requestID];
	}
	[iterableRequests release];
	
	return YES;
}

#pragma mark Low-level push methods
- (void)pushResponseString:(NSString *)theString toRequestWithIdentifier:(NSString *)theIdentifier
{
	[self pushResponseString:theString toRequestWithIdentifier:theIdentifier contentType:@"text/plain"];
}
- (void)pushResponseString:(NSString *)theString toRequestWithIdentifier:(NSString *)theIdentifier contentType:(NSString *)type
{
	[self pushResponse:[theString dataUsingEncoding:NSUTF8StringEncoding] toRequestWithIdentifier:theIdentifier contentType:type headers:nil statusCode:200];
}
- (void)pushResponse:(NSData *)theData toRequestWithIdentifier:(NSString *)theIdentifier contentType:(NSString *)type headers:(NSDictionary *)headers statusCode:(NSInteger)status
{
	if ([openRequestIDs containsObject:theIdentifier])
	{
		BBRequest *request = [requests objectForKey:theIdentifier];
		[request setResponseStatusCode:status];
		[request setResponseContentType:type];
		[request setResponseBody:theData];
		
		if (headers)
		{
			for (NSString *key in headers)
				[request setResponseHeaderValue:[headers objectForKey:key] forHeader:key];
		}
		
		[request sendResponse];
		
		[self removeRequestWithIdentifier:theIdentifier];
	}
	else
		NSLog(@"HaleBopp: No request with identifier %@", theIdentifier);
}

#pragma mark Low-level polling methods
- (NSString *)beginLongPollWithRequest:(BBRequest *)theRequest
{
	NSString *requestID = [[NSProcessInfo processInfo] globallyUniqueString];
	[requests setObject:theRequest forKey:requestID];
	[openRequestIDs addObject:requestID];
	[[theRequest connection] setAssociatedIdentifier:requestID];
	
	if (delegate && [delegate respondsToSelector:@selector(responder:startedLongPollWithRequest:identifier:)])
		[delegate responder:self startedLongPollWithRequest:theRequest identifier:requestID];
	
	return requestID;
}

#pragma mark Request fulfillment handlers
- (void)killRequestWithIdentifier:(NSString *)theIdentifier
{
	if ([openRequestIDs containsObject:theIdentifier])
	{
		BBRequest *theRequest = [requests objectForKey:theIdentifier];
		[[theRequest connection] die];
		
		[self removeRequestWithIdentifier:theIdentifier];
	}
}
- (void)removeRequestWithIdentifier:(NSString *)theIdentifier
{
	if ([openRequestIDs containsObject:theIdentifier])
	{
		[openRequestIDs removeObject:theIdentifier];
		[requests removeObjectForKey:theIdentifier];
		
		for (NSString *channel in channelToRequestMap)
			[[channelToRequestMap objectForKey:channel] removeObject:theIdentifier];
		
		if (delegate && [delegate respondsToSelector:@selector(responder:requestNoLongerAvailableWithIdentifier:)])
			[delegate responder:self requestNoLongerAvailableWithIdentifier:theIdentifier];
	}
}
- (void)connectionDied:(NSNotification *)theNotification
{
	if ([[theNotification object] respondsToSelector:@selector(associatedIdentifier)])
		[self removeRequestWithIdentifier:[[theNotification object] associatedIdentifier]];
}

#pragma mark Responder methods (BBResponder)
- (void)handleRequest:(BBRequest *)theRequest
{
	NSString *channelName = [[theRequest fullPath] substringFromIndex:1];
	if (![openChannels containsObject:channelName])
	{
		BOOL shouldAllow = ([openChannels count] == 0);
		if (delegate && [delegate respondsToSelector:@selector(responder:allowConnectionToNonexistentChannelWithRequest:)])
			shouldAllow = [delegate responder:self allowConnectionToNonexistentChannelWithRequest:theRequest];
		
		if (!shouldAllow)
		{
			[theRequest setResponseStatusCode:404];
			[theRequest setResponseContentType:@"text/html"];
			[theRequest setResponseString:@"<h1>404 File Not Found</h1>"];
			[theRequest sendResponse];
			return;
		}
	}
	
	NSString *requestID = [self beginLongPollWithRequest:theRequest];
	if ([openChannels containsObject:channelName])
		[[channelToRequestMap objectForKey:channelName] addObject:requestID];
}
- (BOOL)repliesAsynchronously
{
	return YES;
}

@end
