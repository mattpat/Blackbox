//
//  BBRequest.m
//  Blackbox
//
//  Created by Matt Patenaude on 1/18/10.
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

#import "BBRequest.h"
#import "BBConnection.h"


#pragma mark Functions
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
			
			[dict setObject:[val stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] forKey:key];
		}
		else
			[dict setObject:[NSNull null] forKey:[keyValPrel objectAtIndex:0]];
	}
}
void BBParsePropertyListIntoDictionary(NSData *postData, NSMutableDictionary *dict)
{
	NSString *err = nil;
	NSDictionary *plist = [NSPropertyListSerialization propertyListFromData:postData mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:&err];
	
	if (plist)
		[dict setDictionary:plist];
	
	if (err)
		[err release];
}

@implementation BBRequest

#pragma mark Initializers
- (id)initWithServer:(BBServer *)theServer connection:(BBConnection *)theConnection message:(CFHTTPMessageRef)theMessage asynchronous:(BOOL)async
{
	if (self = [super init])
	{
		server = [theServer retain];
		connection = [theConnection retain];
		relativePath = nil;
		useAsynchronousResponse = async;
		
		NSURL *requestURL = (NSURL *)CFHTTPMessageCopyRequestURL(theMessage);
		HTTPMethod = (NSString *)CFHTTPMessageCopyRequestMethod(theMessage);
		fullPath = [[[requestURL path] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] copy];
		
		NSDictionary *headers = (NSDictionary *)CFHTTPMessageCopyAllHeaderFields(theMessage);
		requestHeaders = [[NSMutableDictionary alloc] init];
		for (NSString *key in headers)
			[requestHeaders setObject:[headers objectForKey:key] forKey:BBNormalizeHeaderName(key)];
		CFRelease((CFDictionaryRef)headers);
		
		postData = (NSData *)CFHTTPMessageCopyBody(theMessage);
		
		responseData = [[NSData data] retain];
		responseHeaders = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"text/plain", @"Content-Type", nil];
		responseStatusCode = 200;
		responseFilePath = nil;
		
		getParams = [[NSMutableDictionary alloc] init];
		queryString = [[requestURL query] copy];
		BBParseQueryIntoDictionary(queryString, getParams);			
		[requestURL release];
		
		postParams = [[NSMutableDictionary alloc] init];
		if ([postData length] > 0)
		{
			if ([[[self valueForHeader:@"X-PropertyList"] lowercaseString] isEqualToString:@"true"])
				BBParsePropertyListIntoDictionary([self rawPostData], postParams);
			else
				BBParseQueryIntoDictionary([self postString], postParams);
		}
	}
	return self;
}

#pragma mark Dealloactor
- (void)dealloc
{
	[server release];
	[connection release];
	CFRelease((CFStringRef)HTTPMethod);
	[responseData release];
	[responseFilePath release];
	[relativePath release];
	[fullPath release];
	[requestHeaders release];
	[responseHeaders release];
	[queryString release];
	CFRelease((CFDataRef)postData);
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
	return HTTPMethod;
}
- (NSData *)rawPostData
{
	return postData;
}
- (NSString *)postString
{
	NSString *result = [[NSString alloc] initWithData:[self rawPostData] encoding:NSASCIIStringEncoding];
	return [result autorelease];
}
- (NSDictionary *)headers
{
	return requestHeaders;
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
- (NSInteger)responseStatusCode
{
	return responseStatusCode;
}
- (NSDictionary *)responseHeaders
{
	return responseHeaders;
}
- (NSData *)responseData
{
	return responseData;
}
- (NSString *)responseFilePath
{
	return responseFilePath;
}
- (BBConnection *)connection
{
	return connection;
}

#pragma mark Methods
- (NSString *)valueForHeader:(NSString *)theHeader
{
	return [requestHeaders objectForKey:BBNormalizeHeaderName(theHeader)];
}
- (NSString *)valueForResponseHeader:(NSString *)theHeader
{
	return [responseHeaders objectForKey:BBNormalizeHeaderName(theHeader)];
}
- (void)setResponseContentType:(NSString *)theContentType
{
	[responseHeaders setValue:[[theContentType copy] autorelease] forKey:@"Content-Type"];
}
- (void)setResponseStatusCode:(NSInteger)statusCode
{
	responseStatusCode = statusCode;
}
- (void)setResponseHeaderValue:(NSString *)headerValue forHeader:(NSString *)headerName
{
	NSArray *keyArray = [responseHeaders allKeys];
	for (NSString *key in keyArray)
	{
		if ([[key lowercaseString] isEqualToString:[headerName lowercaseString]])
			[responseHeaders removeObjectForKey:key];
	}
	
	if (headerValue != nil)
		[responseHeaders setObject:headerValue forKey:headerName];
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
- (void)respondWithFile:(NSString *)path
{
	if (responseFilePath)
	{
		[responseFilePath release];
		responseFilePath = nil;
	}
	responseFilePath = [path copy];
}
- (void)sendResponse
{
	if (!useAsynchronousResponse)	// do nothing
		return;
	
	[connection sendAsynchronousResponse];
}

@end
