//
//  BBRequest.m
//  Blackbox
//
//  Created by Matt Patenaude on 11/28/08.
//  Copyright 2008 Matt Patenaude. All rights reserved.
//

#import "BBRequest.h"
#import "BBServer.h"
#import "MPTidbits.h"


NSString *BBNormalizeHeaderName(NSString *headerName)
{
	NSMutableArray *headerParts = [[headerName componentsSeparatedByString:@"-"] mutableCopy];
	int numOfParts = [headerParts count];
	for (int i = 0; i < numOfParts; i++)
		[headerParts replaceObjectAtIndex:i withObject:[[[headerParts objectAtIndex:i] lowercaseString] capitalizedString]];
	NSString *result = [headerParts componentsJoinedByString:@"-"];
	[headerParts release];
	
	return result;
}
void BBParseQueryIntoDictionary(NSString *queryString, NSMutableDictionary *dict)
{
	queryString = [queryString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSArray *parts = [queryString componentsSeparatedByString:@"&"];
	NSEnumerator *partEnum = [parts objectEnumerator];
	NSString *part;
	while (part = [partEnum nextObject])
	{
		NSArray *keyValPrel = [part componentsSeparatedByString:@"="];
		if ([keyValPrel count] > 1)
		{
			NSString *key = [keyValPrel objectAtIndex:0];
			NSString *val = [keyValPrel objectAtIndex:1];
			if ([keyValPrel count] > 2)
				val = [[keyValPrel subarrayWithRange:NSMakeRange(1, [keyValPrel count] - 1)] componentsJoinedByString:@"="];
			
			[dict setObject:val forKey:key];
		}
		else
			[dict setObject:[NSNull null] forKey:[keyValPrel objectAtIndex:0]];
	}
}

@implementation BBRequest

#pragma mark Initializers
- (id)initWithServer:(BBServer *)theServer connection:(BBConnection *)theConnection message:(CFHTTPMessageRef)theMessage
{
	if (self = [super init])
	{
		server = [theServer retain];
		connection = [theConnection retain];
		request = (CFHTTPMessageRef)CFRetain(theMessage);
		relativePath = nil;
		
		NSURL *requestURL = (NSURL *)CFHTTPMessageCopyRequestURL(request);
		fullPath = [[[requestURL path] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] copy];
		
		responseData = [[NSData data] retain];
		responseHeaders = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"text/plain", @"Content-Type", nil];
		responseStatusCode = 200;
		
		getParams = [[NSMutableDictionary alloc] init];
		queryString = [[requestURL query] copy];
		BBParseQueryIntoDictionary(queryString, getParams);			
		[requestURL release];
		
		postParams = [[NSMutableDictionary alloc] init];
		if (![[self postString] isEmpty])
			BBParseQueryIntoDictionary([self postString], postParams);
	}
	return self;
}

#pragma mark Dealloactor
- (void)dealloc
{
	[server release];
	[connection release];
	CFRelease(request);
	
	if (responseData != nil)
		[responseData release];
	
	if (relativePath != nil)
		[relativePath release];
	
	[fullPath release];
	[responseHeaders release];
	[queryString release];
	[getParams release];
	[postParams release];
	[super dealloc];
}

#pragma mark Properties
- (NSString *)fullPath
{
	return fullPath;
}
- (NSString *)relativePath
{
	return (relativePath == nil) ? [self fullPath] : relativePath;
}
- (NSString *)HTTPMethod
{
	NSString *method = (NSString *)CFHTTPMessageCopyRequestMethod(request);
	return [method autorelease];
}
- (NSData *)rawPostData
{
	NSData *data = (NSData *)CFHTTPMessageCopyBody(request);
	return [data autorelease];
}
- (NSString *)postString
{
	NSString *result = [[NSString alloc] initWithData:[self rawPostData] encoding:NSASCIIStringEncoding];
	return [result autorelease];
}
- (NSDictionary *)headers
{
	NSDictionary *headers = (NSDictionary *)CFHTTPMessageCopyAllHeaderFields(request);
	return [headers autorelease];
}
- (NSString *)queryString
{
	return queryString;
}
- (NSDictionary *)GETParameters
{
	return [[getParams copy] autorelease];
}
- (NSDictionary *)POSTParameters
{
	return [[postParams copy] autorelease];
}

#pragma mark Methods
- (void)setResponseContentType:(NSString *)theContentType
{
	[responseHeaders setValue:[[theContentType copy] autorelease] forKey:@"Content-Type"];
}
- (void)setResponseStatusCode:(int)statusCode
{
	responseStatusCode = statusCode;
}
- (void)setResponseHeaderValue:(NSString *)headerValue forHeader:(NSString *)headerName
{
	[responseHeaders setValue:headerValue forKey:BBNormalizeHeaderName(headerName)];
}
- (void)setResponseString:(NSString *)theString
{
	[self setResponseBody:[theString dataUsingEncoding:NSUTF8StringEncoding]];
}
- (void)setResponseBody:(NSData *)theData
{
	if (responseData != nil)
	{
		[responseData release];
		responseData = nil;
	}
	responseData = [theData copy];
}
- (void)sendResponse
{
	[server replyWithStatusCode:responseStatusCode headers:responseHeaders body:responseData];
}

#pragma mark Private methods
- (void)_setRelativePath:(NSString *)newRelativePath
{
	if (relativePath != nil)
	{
		[relativePath release];
		relativePath = nil;
	}
	relativePath = [[newRelativePath stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] copy];
}

@end
