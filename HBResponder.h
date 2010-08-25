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


@interface HBResponder : NSObject<BBResponder> {
	NSMutableArray *openRequestIDs;
	NSMutableDictionary *requests;
	id delegate;
}

// Properties
@property(assign) id delegate;

// Push methods
- (void)pushResponseString:(NSString *)theString toRequestWithIdentifier:(NSString *)theIdentifier;
- (void)pushResponseString:(NSString *)theString toRequestWithIdentifier:(NSString *)theIdentifier contentType:(NSString *)type;
- (void)pushResponse:(NSData *)theData toRequestWithIdentifier:(NSString *)theIdentifier contentType:(NSString *)type statusCode:(NSInteger)status;

// Request fulfillment handlers
- (void)removeRequestWithIdentifier:(NSString *)theIdentifier;
- (void)connectionDied:(NSNotification *)theNotification;

// Responder methods (BBResponder)
- (void)handleRequest:(BBRequest *)theRequest;
- (BOOL)repliesAsynchronously;

@end
