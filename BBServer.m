//
//  BBServer.m
//  Blackbox
//
//  Created by Matt Patenaude on 11/26/08.
//  Copyright 2008 Matt Patenaude. All rights reserved.
//

#import "BBServer.h"
#import "BBConnection.h"
#import "BBRequest.h"
#import "BBDefaultResponder.h"
#import "MPTidbits.h"
#import "AsyncSocket.h"


@implementation BBServer

#pragma mark Initializers
- (id)init
{
	return [self initWithPort:BBServerDefaultPort delegate:nil];
}
- (id)initWithPort:(int)thePort
{
	return [self initWithPort:thePort delegate:nil];
}
- (id)initWithPort:(int)thePort delegate:(id)newDelegate
{
	if (self = [super init])
	{
		requests = [[NSMutableArray alloc] init];
		connections = [[NSMutableArray alloc] init];
		responders = [[NSMutableDictionary alloc] init];
		
		portNumber = thePort;
		if (newDelegate != nil)
			delegate = [newDelegate retain];
		
		socket = [[AsyncSocket alloc] initWithDelegate:self];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionDidDie:) name:HTTPConnectionDidDieNotification object:nil];
		
		defaultResponder = [[BBDefaultResponder alloc] init];
	}
	return self;
}

#pragma mark Dealloactor
- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[requests release];
	if (currentRequest != nil)
		[currentRequest release];
	[connections release];
	if (delegate != nil)
		[delegate release];
	[socket disconnect];
	[socket release];
	if (defaultResponder != nil)
		[defaultResponder release];
	[responders release];
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
- (int)port
{
	return portNumber;
}
- (void)setPort:(int)newPort
{
	[self stop];
	portNumber = newPort;
}
- (void)setCurrentRequest:(NSDictionary *)value
{
    [currentRequest autorelease];
    currentRequest = [value retain];
}
- (NSDictionary *)currentRequest
{
	return currentRequest;
}
- (NSObject<BBResponder> *)defaultResponder
{
	return defaultResponder;
}
- (void)setDefaultResponder:(NSObject<BBResponder> *)newResponder
{
	if (defaultResponder != nil)
	{
		[defaultResponder release];
		defaultResponder = nil;
	}
	defaultResponder = [newResponder retain];
}
- (NSDictionary *)responders
{
	return [[responders copy] autorelease];
}

#pragma mark Methods
- (void)setResponder:(NSObject<BBResponder> *)theResponder forLocation:(NSString *)path
{
	[responders setObject:theResponder forKey:path];
}
- (BOOL)start
{
	return [self startWithError:nil];
}
- (BOOL)startWithError:(NSError **)theErr
{
	BOOL success = [socket acceptOnPort:portNumber error:theErr];
	if (!success)
		[self stop];
	else
		portNumber = [socket localPort];
	
	return success;
}
- (void)stop
{
	[socket disconnect];
	[requests removeAllObjects];
	if (currentRequest != nil)
		[currentRequest release];
	[connections removeAllObjects];
}

#pragma mark Private Methods
- (void)onSocket:(AsyncSocket *)sock didAcceptNewSocket:(AsyncSocket *)newSocket
{
	BBConnection *connection;
	connection = [[BBConnection alloc] initWithSocket:newSocket delegate:self];
	if (connection)
	{
		NSIndexSet *insertedIndexes = [NSIndexSet indexSetWithIndex:[connections count]];
		[self willChange:NSKeyValueChangeInsertion valuesAtIndexes:insertedIndexes forKey:@"connections"];
		[connections addObject:connection];
		[self didChange:NSKeyValueChangeInsertion valuesAtIndexes:insertedIndexes forKey:@"connections"];
		[connection release];
	}
}
- (void)connectionDidDie:(NSNotification *)notification
{
	[self _closeConnection:[notification object]];
}
- (void)_closeConnection:(BBConnection *)connection
{
	unsigned connectionIndex = [connections indexOfObjectIdenticalTo:connection];
    if (connectionIndex == NSNotFound)
		return;
	
    // We remove all pending requests pertaining to connection
    NSMutableIndexSet *obsoleteRequests = [NSMutableIndexSet indexSet];
    BOOL stopProcessing = NO;
    int k;
    for (k = 0; k < [requests count]; k++)
	{
        NSDictionary *request = [requests objectAtIndex:k];
        if ([request objectForKey:@"connection"] == connection)
		{
            if (request == [self currentRequest])
				stopProcessing = YES;
            [obsoleteRequests addIndex:k];
        }
    }
    
    NSIndexSet *connectionIndexSet = [NSIndexSet indexSetWithIndex:connectionIndex];
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:obsoleteRequests forKey:@"requests"];
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:connectionIndexSet forKey:@"connections"];
    [requests removeObjectsAtIndexes:obsoleteRequests];
    [connections removeObjectsAtIndexes:connectionIndexSet];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:connectionIndexSet forKey:@"connections"];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:obsoleteRequests forKey:@"requests"];
    
    if (stopProcessing)
	{
        // [delegate stopProcessing];
        [self setCurrentRequest:nil];
    }
    [self _processNextRequestIfNecessary];
}
- (void)_newRequest:(BBRequest *)theRequest connection:(BBConnection *)connection
{
	//NSLog(@"requestWithURL:connection:");
    if ( theRequest == nil )
		return;
    
    NSDictionary *request = [NSDictionary dictionaryWithObjectsAndKeys:
								connection, @"connection",
								[NSCalendarDate date], @"date",
								theRequest, @"request",
								[theRequest fullPath], @"url",
								nil];
    
    NSIndexSet *insertedIndexes = [NSIndexSet indexSetWithIndex:[requests count]];
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:insertedIndexes forKey:@"requests"];
    [requests addObject:request];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:insertedIndexes forKey:@"requests"];
    
    [self _processNextRequestIfNecessary];
}
- (void)_processNextRequestIfNecessary
{
    if ([self currentRequest] == nil && [requests count] > 0)
	{
		[self setCurrentRequest:[requests objectAtIndex:0]];
		
		NSString *matchPath = [[currentRequest objectForKey:@"request"] fullPath];
		//NSLog(@"Obj: %@, lookup: %@", [[currentRequest objectForKey:@"request"] description], matchPath);
		while (matchPath && ![matchPath isEqualToString:@"/"])
		{
			if ([responders containsKey:matchPath])
			{
				BBRequest *theRequest = [currentRequest objectForKey:@"request"];
				[theRequest _setRelativePath:[[theRequest fullPath] substringFromIndex:[matchPath length]]];
				[[responders objectForKey:matchPath] handleRequest:theRequest];
				break;
			}
			else
				matchPath = [matchPath stringByDeletingLastPathComponent];
		}
		
		if (matchPath == nil || [matchPath isEqualToString:@"/"])
			[defaultResponder handleRequest:[currentRequest objectForKey:@"request"]];
    }
}

- (void)replyWithStatusCode:(int)code headers:(NSDictionary *)headers body:(NSData *)body
{
    CFHTTPMessageRef msg;
    msg = CFHTTPMessageCreateResponse(kCFAllocatorDefault, code, NULL, kCFHTTPVersion1_1);
	
    NSEnumerator *keys = [headers keyEnumerator];
    NSString *key;
    while (key = [keys nextObject])
	{
        id value = [headers objectForKey:key];
        if(![value isKindOfClass:[NSString class]])
			value = [value description];
        if(![key isKindOfClass:[NSString class]])
			key = [key description];
		
        CFHTTPMessageSetHeaderFieldValue(msg, (CFStringRef)key, (CFStringRef)value);
    }
	
    if (body)
	{
        NSString *length = [NSString stringWithFormat:@"%d", [body length]];
        CFHTTPMessageSetHeaderFieldValue(msg, (CFStringRef)@"Content-Length", (CFStringRef)length);
        CFHTTPMessageSetBody(msg, (CFDataRef)body);
    }
    
    CFDataRef msgData = CFHTTPMessageCopySerializedMessage(msg);
    @try
	{
		[[(BBConnection *)[[self currentRequest] objectForKey:@"connection"] socket] writeData:(NSData *)msgData withTimeout:WRITE_ERROR_TIMEOUT tag:HTTP_RESPONSE];
    }
    @catch (NSException *exception)
	{
        NSLog(@"Error while sending response (%@): %@", [[self currentRequest] objectForKey:@"url"], [exception  reason]);
    }
    
    CFRelease(msgData);
    CFRelease(msg);
    
    // A reply indicates that the current request has been completed
    // (either successfully of by responding with an error message)
    // Hence we need to remove the current request:
    unsigned index = [requests indexOfObjectIdenticalTo:[self currentRequest]];
    if (index != NSNotFound)
	{
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:index];
        [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexSet forKey:@"requests"];
        [requests removeObjectsAtIndexes:indexSet];
        [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexSet forKey:@"requests"];
    }
    [self setCurrentRequest:nil];
    [self _processNextRequestIfNecessary];
}

- (void)replyWithData:(NSData *)data MIMEType:(NSString *)type
{
    NSDictionary *headers = [NSDictionary dictionaryWithObject:type forKey:@"Content-Type"];
    [self replyWithStatusCode:200 headers:headers body:data];  // 200 = 'OK'
}

- (void)replyWithStatusCode:(int)code message:(NSString *)message
{
    NSData *body = [message dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    [self replyWithStatusCode:code headers:nil body:body];
}

@end
