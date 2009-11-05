//
//  BBServer.h
//  Blackbox
//
//  Created by Matt Patenaude on 11/26/08.
//  Copyright 2008 Matt Patenaude. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BBResponder.h"


// Constants
#define BBServerDefaultPort 8080

// Forward Declarations
@class BBConnection;
@class BBRequest;
@class AsyncSocket;

@interface BBServer : NSObject {
	id delegate;
	
	int portNumber;
	AsyncSocket *socket;
	
	NSMutableArray *requests;
	NSMutableArray *connections;
	NSDictionary *currentRequest;
	
	NSMutableDictionary *responders;
	
	NSObject<BBResponder> *defaultResponder;
}

// Initializers
- (id)initWithPort:(int)thePort;
- (id)initWithPort:(int)thePort delegate:(id)newDelegate;	// designated initializer

// Properties
- (id)delegate;
- (void)setDelegate:(id)newDelegate;
- (int)port;
- (void)setPort:(int)newPort;
- (NSDictionary *)currentRequest;
- (void)setCurrentRequest:(NSDictionary *)value;
- (NSObject<BBResponder> *)defaultResponder;
- (void)setDefaultResponder:(NSObject<BBResponder> *)newResponder;
- (NSDictionary *)responders;

// Methods
- (void)setResponder:(NSObject<BBResponder> *)theResponder forLocation:(NSString *)path;
- (BOOL)start;
- (BOOL)startWithError:(NSError **)theErr;
- (void)stop;

// Private Methods
- (void)onSocket:(AsyncSocket *)sock didAcceptNewSocket:(AsyncSocket *)newSocket;
- (void)connectionDidDie:(NSNotification *)notification;
- (void)_closeConnection:(BBConnection *)connection;
- (void)_newRequest:(BBRequest *)theRequest connection:(BBConnection *)connection;

- (void)_processNextRequestIfNecessary;

- (void)replyWithStatusCode:(int)code
                    headers:(NSDictionary *)headers
                       body:(NSData *)body;
- (void)replyWithData:(NSData *)data MIMEType:(NSString *)type;
- (void)replyWithStatusCode:(int)code message:(NSString *)message;

@end
