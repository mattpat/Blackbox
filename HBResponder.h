//
//  HBResponder.h
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

#import <Foundation/Foundation.h>
#import "BBResponder.h"


// Constants
#define HBDefaultHashTimestampThreshold 900

#define HBClientStateActive @"active"
#define HBClientStateIdle @"idle"

#define HBClientActionRegister @"register"
#define HBClientActionUnregister @"unregister"
#define HBClientActionPoll @"poll"
#define HBClientActionIdle @"idle"
#define HBClientActionPing @"ping"
#define HBClientActionHeartbeat @"heartbeat"

#define HBClientFeatureReceipts @"receipts"

#define HBErrorIncompleteRequest @"Incomplete Request"
#define HBErrorUnrecognizedAction @"Unrecognized Action"
#define HBErrorInvalidHash @"Invalid Hash/Timestamp Combo (Check System Clock)"
#define HBErrorRegistrationDenied @"Registration Denied"
#define HBErrorUnrecognizedClient @"Unrecognized Client Identifier"

@interface HBResponder : NSObject<BBResponder> {
	NSMutableArray *openRequestIDs;
	NSMutableDictionary *requests;
	id delegate;
	
	NSMutableSet *openChannels;
	NSMutableDictionary *channelToRequestMap;
}

// Properties
@property(assign) id delegate;

// High-level client methods
- (BOOL)createChannel:(NSString *)channelName;
- (BOOL)destroyChannel:(NSString *)channelName;
- (BOOL)pushString:(NSString *)theString toChannel:(NSString *)theChannel;
- (BOOL)pushString:(NSString *)theString contentType:(NSString *)type toChannel:(NSString *)theChannel;
- (BOOL)pushPropertyList:(id)thePlist toChannel:(NSString *)theChannel;
- (BOOL)pushData:(NSData *)theData contentType:(NSString *)type headers:(NSDictionary *)headers toChannel:(NSString *)theChannel;

// Low-level push methods
- (void)pushResponseString:(NSString *)theString toRequestWithIdentifier:(NSString *)theIdentifier;
- (void)pushResponseString:(NSString *)theString toRequestWithIdentifier:(NSString *)theIdentifier contentType:(NSString *)type;
- (void)pushResponse:(NSData *)theData toRequestWithIdentifier:(NSString *)theIdentifier contentType:(NSString *)type headers:(NSDictionary *)headers statusCode:(NSInteger)status;

@end
