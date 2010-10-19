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

// High-level HaleBopp utility methods
- (void)replyToHaleBoppRequest:(BBRequest *)theRequest withBody:(NSData *)theBody;
- (void)replyToHaleBoppRequest:(BBRequest *)theRequest withPropertyList:(id)thePlist;
- (void)replyToHaleBoppRequest:(BBRequest *)theRequest withSuccess:(BOOL)success errorString:(NSString *)theError userInfo:(NSDictionary *)userInfo;
- (BOOL)hashIsValidForRequest:(BBRequest *)theRequest;
- (void)changeClient:(NSString *)theIdentifier toState:(NSString *)theState withRequest:(BBRequest *)theRequest;
- (void)closePollRequestsForClient:(NSString *)theIdentifier;
- (void)removeClient:(NSString *)theIdentifier;
- (BOOL)processNextQueueItemForClient:(NSString *)theIdentifier;
- (void)updateFeaturesForClient:(NSString *)theIdentifier fromRequest:(BBRequest *)theRequest;
- (void)checkReceiptsForClient:(NSString *)theIdentifier inRequest:(BBRequest *)theRequest;

// High-level HaleBopp actions
- (void)registerClient:(NSString *)theIdentifier withRequest:(BBRequest *)theRequest;
- (void)unregisterClient:(NSString *)theIdentifier withRequest:(BBRequest *)theRequest;
- (void)beginClientPoll:(NSString *)theIdentifier withRequest:(BBRequest *)theRequest;
- (void)idleClient:(NSString *)theIdentifier withRequest:(BBRequest *)theRequest;
- (void)pingClient:(NSString *)theIdentifier withRequest:(BBRequest *)theRequest;

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
		
		clientStates = [[NSMutableDictionary alloc] init];
		clientSessionKeys = [[NSMutableDictionary alloc] init];
		clientFeatures = [[NSMutableDictionary alloc] init];
		clientPollRequests = [[NSMutableDictionary alloc] init];
		clientPendingPushes = [[NSMutableDictionary alloc] init];
		clientPendingReceipts = [[NSMutableDictionary alloc] init];
	}
	return self;
}

#pragma mark Deallocator
- (void)dealloc
{
	[openRequestIDs release];
	[requests release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[clientStates release];
	[clientSessionKeys release];
	[clientFeatures release];
	[clientPollRequests release];
	[clientPendingPushes release];
	[clientPendingReceipts release];
	[super dealloc];
}

#pragma mark Properties
@synthesize delegate;

#pragma mark High-level client methods
- (NSString *)pushString:(NSString *)theString toClient:(NSString *)theIdentifier
{
	return [self pushString:theString contentType:@"text/plain" toClient:theIdentifier];
}
- (NSString *)pushString:(NSString *)theString contentType:(NSString *)type toClient:(NSString *)theIdentifier
{
	return [self pushData:[theString dataUsingEncoding:NSUTF8StringEncoding] contentType:type headers:nil toClient:theIdentifier];
}
- (NSString *)pushPropertyList:(id)thePlist toClient:(NSString *)theIdentifier
{
	NSString *err = nil;
	NSData *plist = [NSPropertyListSerialization dataFromPropertyList:thePlist format:NSPropertyListXMLFormat_v1_0 errorDescription:&err];
	
	if (err)
		[err release];
	
	return [self pushData:plist contentType:@"application/xml" headers:[NSDictionary dictionaryWithObject:@"true" forKey:@"X-PropertyList"] toClient:theIdentifier];
}
- (NSString *)pushData:(NSData *)theData contentType:(NSString *)type headers:(NSDictionary *)headers toClient:(NSString *)theIdentifier
{
	NSMutableArray *pending = [clientPendingPushes objectForKey:theIdentifier];
	if (pending == nil)
	{
		NSLog(@"HaleBop: attempt to push to unknown client \"%@\"", theIdentifier);
		return nil;
	}
	
	if (!headers)
		headers = [NSDictionary dictionary];
	
	NSString *pushID = [[NSProcessInfo processInfo] globallyUniqueString];
	
	NSDictionary *push = [NSDictionary dictionaryWithObjectsAndKeys:type, @"type", theData, @"data", headers, @"headers", pushID, @"ID", nil];
	[pending addObject:push];
	BOOL immediate = [self processNextQueueItemForClient:theIdentifier];
	
	return (immediate) ? nil : pushID;
}
- (BOOL)pushWithIdentifier:(NSString *)pushID hasCompletedForClient:(NSString *)theIdentifier
{
	NSMutableArray *pending = [clientPendingPushes objectForKey:theIdentifier];
	NSMutableArray *receipts = [clientPendingReceipts objectForKey:theIdentifier];
	if (pending == nil)
	{
		NSLog(@"HaleBop: attempt to push to unknown client \"%@\"", theIdentifier);
		return NO;
	}
	
	if ([receipts containsObject:pushID])
		return NO;
	
	for (NSDictionary *push in pending)
	{
		if ([[push objectForKey:@"ID"] isEqualToString:pushID])
			return NO;
	}
	
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

#pragma mark High-level HaleBopp utility methods
- (void)replyToHaleBoppRequest:(BBRequest *)theRequest withBody:(NSData *)theBody
{
	[theRequest setResponseHeaderValue:@"true" forHeader:@"X-HaleBopp"];
	[theRequest setResponseBody:theBody];
	[theRequest sendResponse];
}
- (void)replyToHaleBoppRequest:(BBRequest *)theRequest withPropertyList:(id)thePlist
{
	[theRequest setResponseHeaderValue:@"true" forHeader:@"X-PropertyList"];
	[theRequest setResponseContentType:@"application/xml"];
	
	NSString *err = nil;
	NSData *plist = [NSPropertyListSerialization dataFromPropertyList:thePlist format:NSPropertyListXMLFormat_v1_0 errorDescription:&err];
	
	if (err)
		[err release];
	
	[self replyToHaleBoppRequest:theRequest withBody:plist];
}
- (void)replyToHaleBoppRequest:(BBRequest *)theRequest withSuccess:(BOOL)success errorString:(NSString *)theError userInfo:(NSDictionary *)userInfo
{
	[theRequest setResponseHeaderValue:((success) ? @"true" : @"false") forHeader:@"X-HaleBopp-Success"];
	
	NSString *responseString = (theError) ? theError : @"OK";
	
	if (userInfo)
	{
		for (NSString *key in userInfo)
			[theRequest setResponseHeaderValue:[userInfo objectForKey:key] forHeader:[NSString stringWithFormat:@"X-HaleBopp-%@", key]];
	}
	
	[self replyToHaleBoppRequest:theRequest withBody:[responseString dataUsingEncoding:NSASCIIStringEncoding]];
}
- (BOOL)hashIsValidForRequest:(BBRequest *)theRequest
{
	NSString *clientID = [theRequest valueForHeader:@"X-HaleBopp-ClientIdentifier"];
	NSString *hash = [theRequest valueForHeader:@"X-HaleBopp-SecureHash"];
	NSString *tsString = [theRequest valueForHeader:@"X-HaleBopp-Timestamp"];
	
	if (clientID == nil || hash == nil || tsString == nil)
		return NO;
	
	// first, valid hash against session key
	NSString *sessionKey = [clientSessionKeys objectForKey:clientID];
	if (sessionKey == nil)
		return NO;
	
	NSString *necessaryHash = [[[sessionKey stringByAppendingString:tsString] HBSHA1Hash] lowercaseString];
	if (![[hash lowercaseString] isEqualToString:necessaryHash])
		return NO;
	
	// now, check timestamp
	NSTimeInterval threshold = HBDefaultHashTimestampThreshold;
	if (delegate && [delegate respondsToSelector:@selector(secureHashTimestampThresholdForResponder:)])
		threshold = [delegate secureHashTimestampThresholdForResponder:self];
	
	NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
	NSTimeInterval timestamp = [tsString doubleValue];
	
	NSTimeInterval difference = fabs(now - timestamp);
	return (difference <= threshold);
}
- (void)changeClient:(NSString *)theIdentifier toState:(NSString *)theState withRequest:(BBRequest *)theRequest
{
	NSString *oldState = [clientStates objectForKey:theIdentifier];
	[clientStates setObject:theState forKey:theIdentifier];
	
	if (oldState && ![oldState isEqualToString:theState])
	{
		if (delegate && [delegate respondsToSelector:@selector(responder:client:hasChangedStatus:withRequest:)])
			[delegate responder:self client:theIdentifier hasChangedStatus:theState withRequest:theRequest];
	}
}
- (void)closePollRequestsForClient:(NSString *)theIdentifier
{
	NSString *req = [clientPollRequests objectForKey:theIdentifier];
	if (req)
	{
		[self killRequestWithIdentifier:req];
		[clientPollRequests removeObjectForKey:theIdentifier];
	}
}
- (void)removeClient:(NSString *)theIdentifier
{
	[clientStates removeObjectForKey:theIdentifier];
	[clientSessionKeys removeObjectForKey:theIdentifier];
	[clientFeatures removeObjectForKey:theIdentifier];
	[clientPendingPushes removeObjectForKey:theIdentifier];
	[clientPendingReceipts removeObjectForKey:theIdentifier];
	[self closePollRequestsForClient:theIdentifier];
}
- (BOOL)processNextQueueItemForClient:(NSString *)theIdentifier
{
	if ([[clientStates objectForKey:theIdentifier] isEqualToString:HBClientStateIdle])
		return NO;
	
	NSMutableArray *pending = [clientPendingPushes objectForKey:theIdentifier];
	NSMutableArray *receipts = [clientPendingReceipts objectForKey:theIdentifier];
	if (!pending || [pending count] < 1)
		return NO;
	
	NSString *requestID = [clientPollRequests objectForKey:theIdentifier];
	if (requestID)
	{
		NSDictionary *push = [[pending objectAtIndex:0] retain];
		[pending removeObjectAtIndex:0];
		
		NSMutableDictionary *headers = [NSMutableDictionary dictionaryWithObject:[push objectForKey:@"ID"] forKey:@"X-HaleBopp-PushID"];
		[headers addEntriesFromDictionary:[push objectForKey:@"headers"]];
		
		[self pushResponse:[push objectForKey:@"data"] toRequestWithIdentifier:requestID contentType:[push objectForKey:@"type"] headers:headers statusCode:200];
		
		[clientPollRequests removeObjectForKey:theIdentifier];
		[self changeClient:theIdentifier toState:HBClientStateIdle withRequest:nil];
		
		if (delegate && [delegate respondsToSelector:@selector(responder:pushDispatched:forClient:)])
			[delegate responder:self pushDispatched:[push objectForKey:@"ID"] forClient:theIdentifier];
		
		BOOL waitingForReceipt = NO;
		if (![[clientFeatures objectForKey:theIdentifier] containsObject:HBClientFeatureReceipts])
		{
			if (delegate && [delegate respondsToSelector:@selector(responder:pushCompleted:forClient:)])
				[delegate responder:self pushCompleted:[push objectForKey:@"ID"] forClient:theIdentifier];
		}
		else
		{
			[receipts addObject:[push objectForKey:@"ID"]];
			waitingForReceipt = YES;
		}
		
		[push release];
		return (!waitingForReceipt);
	}
	
	return NO;
}
- (void)updateFeaturesForClient:(NSString *)theIdentifier fromRequest:(BBRequest *)theRequest
{
	NSString *features = [theRequest valueForHeader:@"X-HaleBopp-Supports"];
	NSMutableArray *cFeatures = [clientFeatures objectForKey:theIdentifier];
	if (features != nil && cFeatures != nil)
	{
		NSArray *featureList = [features componentsSeparatedByString:@","];
		
		[cFeatures removeAllObjects];
		for (NSString *aFeature in featureList)
			[cFeatures addObject:[aFeature stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
	}
}
- (void)checkReceiptsForClient:(NSString *)theIdentifier inRequest:(BBRequest *)theRequest
{
	NSString *receipts = [theRequest valueForHeader:@"X-HaleBopp-Receipt"];
	NSMutableArray *cReceipts = [clientPendingReceipts objectForKey:theIdentifier];
	if (receipts)
	{
		NSArray *receiptList = [receipts componentsSeparatedByString:@","];
		
		for (NSString *aReceipt in receiptList)
		{
			[cReceipts removeObject:aReceipt];
			
			if (delegate && [delegate respondsToSelector:@selector(responder:pushCompleted:forClient:)])
				[delegate responder:self pushCompleted:aReceipt forClient:theIdentifier];
		}
	}
}

#pragma mark High-level HaleBopp actions
- (void)registerClient:(NSString *)theIdentifier withRequest:(BBRequest *)theRequest
{
	BOOL reregister = [[clientSessionKeys allKeys] containsObject:theIdentifier];
	if (reregister)
	{
		// we're reregistering, which means we may need a hash
		BOOL usingHashes = YES;
		BOOL requireHash = YES;
		if (delegate && [delegate respondsToSelector:@selector(requireSecureHashesForResponder:)])
			usingHashes = [delegate requireSecureHashesForResponder:self];
		
		if (!usingHashes)
			requireHash = NO;
		else
		{
			if (delegate && [delegate respondsToSelector:@selector(responder:allowReregistrationWithoutSecureHashForRequest:)])
				requireHash = (![delegate responder:self allowReregistrationWithoutSecureHashForRequest:theRequest]);
		}
		
		if (requireHash && ![self hashIsValidForRequest:theRequest])
		{
			[self replyToHaleBoppRequest:theRequest withSuccess:NO errorString:HBErrorInvalidHash userInfo:nil];
			return;
		}
	}
	
	BOOL allowRegistration = YES;
	if (delegate && [delegate respondsToSelector:@selector(responder:allowRegistrationForClient:withRequest:)])
		allowRegistration = [delegate responder:self allowRegistrationForClient:theIdentifier withRequest:theRequest];
	
	if (!allowRegistration)
	{
		[self replyToHaleBoppRequest:theRequest withSuccess:NO errorString:HBErrorRegistrationDenied userInfo:nil];
		return;
	}
	
	NSString *sessionKey = (reregister) ? [clientSessionKeys objectForKey:theIdentifier] : [[NSProcessInfo processInfo] globallyUniqueString];
	NSDictionary *userInfo = (reregister) ? nil : [NSDictionary dictionaryWithObject:sessionKey forKey:@"SessionKey"];
	
	if (reregister)
		[clientStates removeObjectForKey:theIdentifier];
	
	[clientSessionKeys setObject:sessionKey forKey:theIdentifier];
	[clientFeatures setObject:[NSMutableArray array] forKey:theIdentifier];
	[clientPendingPushes setObject:[NSMutableArray array] forKey:theIdentifier];
	[clientPendingReceipts setObject:[NSMutableArray array] forKey:theIdentifier];
	[self changeClient:theIdentifier toState:HBClientStateIdle withRequest:theRequest];
	
	[self updateFeaturesForClient:theIdentifier fromRequest:theRequest];
	
	[self replyToHaleBoppRequest:theRequest withSuccess:YES errorString:nil userInfo:userInfo];
	
	if (delegate && [delegate respondsToSelector:@selector(responder:clientRegistered:withRequest:)])
		[delegate responder:self clientRegistered:theIdentifier withRequest:theRequest];
}
- (void)unregisterClient:(NSString *)theIdentifier withRequest:(BBRequest *)theRequest
{
	// we're unregistering, which means we may need a hash
	BOOL usingHashes = YES;
	BOOL requireHash = YES;
	if (delegate && [delegate respondsToSelector:@selector(requireSecureHashesForResponder:)])
		usingHashes = [delegate requireSecureHashesForResponder:self];
	
	if (!usingHashes)
		requireHash = NO;
	else
	{
		if (delegate && [delegate respondsToSelector:@selector(responder:allowUnregistrationWithoutSecureHashForRequest:)])
			requireHash = (![delegate responder:self allowUnregistrationWithoutSecureHashForRequest:theRequest]);
	}
	
	if (requireHash && ![self hashIsValidForRequest:theRequest])
	{
		[self replyToHaleBoppRequest:theRequest withSuccess:NO errorString:HBErrorInvalidHash userInfo:nil];
		return;
	}
	
	if (![[clientSessionKeys allKeys] containsObject:theIdentifier])
	{
		[self replyToHaleBoppRequest:theRequest withSuccess:NO errorString:HBErrorUnrecognizedClient userInfo:nil];
		return;
	}
	
	[self removeClient:theIdentifier];
	[self replyToHaleBoppRequest:theRequest withSuccess:YES errorString:nil userInfo:nil];
	
	if (delegate && [delegate respondsToSelector:@selector(responder:clientUnregistered:withRequest:)])
		[delegate responder:self clientUnregistered:theIdentifier withRequest:theRequest];
}
- (void)beginClientPoll:(NSString *)theIdentifier withRequest:(BBRequest *)theRequest
{
	BOOL requireHash = YES;
	if (delegate && [delegate respondsToSelector:@selector(requireSecureHashesForResponder:)])
		requireHash = [delegate requireSecureHashesForResponder:self];
	
	if (requireHash && ![self hashIsValidForRequest:theRequest])
	{
		[self replyToHaleBoppRequest:theRequest withSuccess:NO errorString:HBErrorInvalidHash userInfo:nil];
		return;
	}
	
	if (![[clientSessionKeys allKeys] containsObject:theIdentifier])
	{
		[self replyToHaleBoppRequest:theRequest withSuccess:NO errorString:HBErrorUnrecognizedClient userInfo:nil];
		return;
	}
	
	[self closePollRequestsForClient:theIdentifier];
	
	NSString *requestID = [self beginLongPollWithRequest:theRequest];
	[clientPollRequests setObject:requestID forKey:theIdentifier];
	
	[self changeClient:theIdentifier toState:HBClientStateActive withRequest:theRequest];
	
	[self processNextQueueItemForClient:theIdentifier];
}
- (void)idleClient:(NSString *)theIdentifier withRequest:(BBRequest *)theRequest
{
	BOOL requireHash = YES;
	if (delegate && [delegate respondsToSelector:@selector(requireSecureHashesForResponder:)])
		requireHash = [delegate requireSecureHashesForResponder:self];
	
	if (requireHash && ![self hashIsValidForRequest:theRequest])
	{
		[self replyToHaleBoppRequest:theRequest withSuccess:NO errorString:HBErrorInvalidHash userInfo:nil];
		return;
	}
	
	if (![[clientSessionKeys allKeys] containsObject:theIdentifier])
	{
		[self replyToHaleBoppRequest:theRequest withSuccess:NO errorString:HBErrorUnrecognizedClient userInfo:nil];
		return;
	}
	
	[self closePollRequestsForClient:theIdentifier];
	[self replyToHaleBoppRequest:theRequest withSuccess:YES errorString:nil userInfo:nil];
	
	[self changeClient:theIdentifier toState:HBClientStateIdle withRequest:theRequest];
}
- (void)pingClient:(NSString *)theIdentifier withRequest:(BBRequest *)theRequest
{
	if (![[clientSessionKeys allKeys] containsObject:theIdentifier])
	{
		[self replyToHaleBoppRequest:theRequest withSuccess:NO errorString:HBErrorUnrecognizedClient userInfo:nil];
		return;
	}
	
	NSDictionary *userInfo = nil;
	NSString *hash = [theRequest valueForHeader:@"X-HaleBopp-SecureHash"];
	if (hash)
		userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:[self hashIsValidForRequest:theRequest]] forKey:@"ValidHash"];
	
	[self replyToHaleBoppRequest:theRequest withSuccess:YES errorString:nil userInfo:userInfo];
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
		
		if (delegate && [delegate respondsToSelector:@selector(responder:requestNoLongerAvailableWithIdentifier:)])
			[delegate responder:self requestNoLongerAvailableWithIdentifier:theIdentifier];
	}
}
- (void)connectionDied:(NSNotification *)theNotification
{
	if ([[theNotification object] respondsToSelector:@selector(associatedIdentifier)])
	{
		NSArray *associatedClients = [clientPollRequests allKeysForObject:[[theNotification object] associatedIdentifier]];
		for (NSString *clientIdentifier in associatedClients)
		{
			[self changeClient:clientIdentifier toState:HBClientStateIdle withRequest:nil];
			[clientPollRequests removeObjectForKey:clientIdentifier];
		}
		
		[self removeRequestWithIdentifier:[[theNotification object] associatedIdentifier]];
	}
}

#pragma mark Responder methods (BBResponder)
- (void)handleRequest:(BBRequest *)theRequest
{
	if ([[[theRequest valueForHeader:@"X-HaleBopp"] lowercaseString] isEqualToString:@"true"])
	{
		NSString *action = [[theRequest valueForHeader:@"X-HaleBopp-Action"] lowercaseString];
		NSString *clientIdentifier = [theRequest valueForHeader:@"X-HaleBopp-ClientIdentifier"];
		
		if (action == nil || clientIdentifier == nil)
		{
			[self replyToHaleBoppRequest:theRequest withSuccess:NO errorString:HBErrorIncompleteRequest userInfo:nil];
			return;
		}
		
		if ([action isEqualToString:HBClientActionRegister])
			[self registerClient:clientIdentifier withRequest:theRequest];
		else
		{
			BOOL requireHash = YES;
			if (delegate && [delegate respondsToSelector:@selector(requireSecureHashesForResponder:)])
				requireHash = [delegate requireSecureHashesForResponder:self];
			
			if (!requireHash || [self hashIsValidForRequest:theRequest])
			{
				[self updateFeaturesForClient:clientIdentifier fromRequest:theRequest];
				if ([[clientFeatures objectForKey:clientIdentifier] containsObject:HBClientFeatureReceipts])
					[self checkReceiptsForClient:clientIdentifier inRequest:theRequest];
			}
			
			if ([action isEqualToString:HBClientActionUnregister])
				[self unregisterClient:clientIdentifier withRequest:theRequest];
			else if ([action isEqualToString:HBClientActionPoll])
				[self beginClientPoll:clientIdentifier withRequest:theRequest];
			else if ([action isEqualToString:HBClientActionIdle])
				[self idleClient:clientIdentifier withRequest:theRequest];
			else if ([action isEqualToString:HBClientActionPing])
				[self pingClient:clientIdentifier withRequest:theRequest];
			else
				[self replyToHaleBoppRequest:theRequest withSuccess:NO errorString:HBErrorUnrecognizedAction userInfo:nil];
		}
	}
	else
		[self beginLongPollWithRequest:theRequest];
}
- (BOOL)repliesAsynchronously
{
	return YES;
}

@end
