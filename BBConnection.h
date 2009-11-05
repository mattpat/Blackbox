//
//  BBConnection.h
//  Blackbox
//
//  Created by Matt Patenaude on 11/26/08.
//  Copyright 2008 Matt Patenaude. All rights reserved.
//

#import <Cocoa/Cocoa.h>


// Constants
// Define the various timeouts (in seconds) for various parts of the HTTP process
#define READ_TIMEOUT        -1
#define WRITE_HEAD_TIMEOUT  30
#define WRITE_BODY_TIMEOUT  -1
#define WRITE_ERROR_TIMEOUT 30

// Define the various tags we'll use to differentiate what it is we're currently doing
#define HTTP_REQUEST           15
#define HTTP_PARTIAL_RESPONSE  29
#define HTTP_RESPONSE          30

#define HTTPConnectionDidDieNotification  @"HTTPConnectionDidDie"

// Forward declarations
@class AsyncSocket;

@interface BBConnection : NSObject {
	id delegate;
	
	AsyncSocket *socket;
    CFHTTPMessageRef message;
    BOOL isMessageComplete;
}

// Initializers
- (id)initWithSocket:(AsyncSocket *)newSocket delegate:(id)newDelegate;

// Properties
- (id)delegate;
- (void)setDelegate:(id)newDelegate;
- (AsyncSocket *)socket;

// AsyncSocket delegate methods
- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData*)data withTag:(long)tag;
- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag;
- (void)onSocketDidDisconnect:(AsyncSocket *)sock;

@end
