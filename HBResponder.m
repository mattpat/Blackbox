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


@implementation HBResponder

#pragma mark Initializers
- (id)init
{
	if (self = [super init])
	{
		openRequestIDs = [[NSMutableArray alloc] init];
		requests = [[NSMutableDictionary alloc] init];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionDied:) name:HTTPConnectionDidDieNotification object:nil];
	}
	return self;
}

#pragma mark Deallocator
- (void)dealloc
{
	[openRequestIDs release];
	[requests release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

#pragma mark Properties
@synthesize delegate;

#pragma mark Push methods
- (void)pushResponseString:(NSString *)theString toRequestWithIdentifier:(NSString *)theIdentifier
{
	[self pushResponseString:theString toRequestWithIdentifier:theIdentifier contentType:@"text/plain"];
}
- (void)pushResponseString:(NSString *)theString toRequestWithIdentifier:(NSString *)theIdentifier contentType:(NSString *)type
{
	[self pushResponse:[theString dataUsingEncoding:NSUTF8StringEncoding] toRequestWithIdentifier:theIdentifier contentType:type statusCode:200];
}
- (void)pushResponse:(NSData *)theData toRequestWithIdentifier:(NSString *)theIdentifier contentType:(NSString *)type statusCode:(NSInteger)status
{
	if ([openRequestIDs containsObject:theIdentifier])
	{
		BBRequest *request = [requests objectForKey:theIdentifier];
		[request setResponseStatusCode:status];
		[request setResponseContentType:type];
		[request setResponseBody:theData];
		[request sendResponse];
		
		[self removeRequestWithIdentifier:theIdentifier];
	}
	else
		NSLog(@"HaleBopp: No request with identifier %@", theIdentifier);
}

#pragma mark Request fulfillment handlers
- (void)removeRequestWithIdentifier:(NSString *)theIdentifier
{
	if ([openRequestIDs containsObject:theIdentifier])
	{
		[openRequestIDs removeObject:theIdentifier];
		[requests removeObjectForKey:theIdentifier];
		
		if (delegate && [delegate respondsToSelector:@selector(requestNoLongerAvailableWithIdentifier:)])
			[delegate requestNoLongerAvailableWithIdentifier:theIdentifier];
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
	NSString *requestID = [[NSProcessInfo processInfo] globallyUniqueString];
	[requests setObject:theRequest forKey:requestID];
	[openRequestIDs addObject:requestID];
	[[theRequest connection] setAssociatedIdentifier:requestID];
	
	if (delegate && [delegate respondsToSelector:@selector(startedLongPollWithRequest:identifier:)])
		[delegate startedLongPollWithRequest:theRequest identifier:requestID];
}
- (BOOL)repliesAsynchronously
{
	return YES;
}

@end
