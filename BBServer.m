//
//  BBServer.m
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

#import "BBServer.h"
#import "BBConnection.h"


@implementation BBServer

#pragma mark Initializers
- (id)init
{
	if (self = [super init])
	{
		connectionClass = [BBConnection self];
		responders = [[NSMutableDictionary alloc] init];
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6
		handlers = [[NSMutableDictionary alloc] init];
#endif
	}
	return self;
}

#pragma mark Deallocator
- (void)dealloc
{
	[defaultResponder release];
	[responders release];
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6
	[defaultHandler release];
	[handlers release];
#endif
	[super dealloc];
}

#pragma mark Responder methods
- (NSObject<BBResponder> *)defaultResponder
{
	return defaultResponder;
}
- (void)setDefaultResponder:(NSObject<BBResponder> *)newResponder
{
	if (defaultResponder)
	{
		[defaultResponder release];
		defaultResponder = nil;
	}
	defaultResponder = [newResponder retain];
}
- (NSObject<BBResponder> *)responderForPath:(NSString *)thePath
{
	NSString *matchPath = thePath;
	NSObject<BBResponder> *theResponder = defaultResponder;
	
	if ([matchPath length] < 1)
		matchPath = @"/";
	
	if (![[matchPath substringToIndex:1] isEqualToString:@"/"])
		matchPath = [@"/" stringByAppendingString:matchPath];
	
	while (matchPath && ![matchPath isEqualToString:@"/"])
	{
		if ([[responders allKeys] containsObject:matchPath])
		{
			theResponder = [responders objectForKey:matchPath];
			break;
		}
		else
			matchPath = [matchPath stringByDeletingLastPathComponent];
	}
	
	return theResponder;
}
- (void)setResponder:(NSObject<BBResponder> *)theResponder forPath:(NSString *)thePath
{	
	if ([thePath length] == 0 || [thePath isEqualToString:@"/"])
		[self setDefaultResponder:theResponder];
	else
	{
		if (![[thePath substringToIndex:1] isEqualToString:@"/"])
			thePath = [@"/" stringByAppendingString:thePath];
		
		[responders setObject:theResponder forKey:thePath];
	}
}
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6
- (BBResponseHandler)defaultHandler
{
	return defaultHandler;
}
- (void)setDefaultHandler:(BBResponseHandler)theHandler
{
	if (defaultHandler)
	{
		[defaultHandler release];
		defaultHandler = nil;
	}
	defaultHandler = [theHandler copy];
}
- (BBResponseHandler)handlerForPath:(NSString *)thePath
{
	NSString *matchPath = thePath;
	BBResponseHandler theHandler = defaultHandler;
	
	if ([matchPath length] < 1)
		matchPath = @"/";
	
	if (![[matchPath substringToIndex:1] isEqualToString:@"/"])
		matchPath = [@"/" stringByAppendingString:matchPath];
	
	while (matchPath && ![matchPath isEqualToString:@"/"])
	{
		if ([[handlers allKeys] containsObject:matchPath])
		{
			theHandler = [handlers objectForKey:matchPath];
			break;
		}
		else
			matchPath = [matchPath stringByDeletingLastPathComponent];
	}
	
	return theHandler;
}
- (void)setHandler:(BBResponseHandler)theHandler forPath:(NSString *)thePath
{
	if ([thePath length] == 0 || [thePath isEqualToString:@"/"])
		[self setDefaultHandler:theHandler];
	else
	{
		if (![[thePath substringToIndex:1] isEqualToString:@"/"])
			thePath = [@"/" stringByAppendingString:thePath];
		
		[handlers setObject:[[theHandler copy] autorelease] forKey:thePath];
	}
}
#endif

@end
