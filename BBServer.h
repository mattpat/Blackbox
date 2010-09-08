//
//  BBServer.h
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

#import <Foundation/Foundation.h>
#import "HTTPServer.h"
#import "BBResponder.h"
#import "BBRequest.h"


// Constants
#ifndef MAC_OS_X_VERSION_10_6
#define MAC_OS_X_VERSION_10_6 1060
#endif

#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6
// Types
typedef void (^BBResponseHandler)(BBRequest *);
#endif

@interface BBServer : HTTPServer {
	NSObject<BBResponder> *defaultResponder;
	NSMutableDictionary *responders;
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6
	BBResponseHandler defaultHandler;
	NSMutableDictionary *handlers;
#endif
}

// Responder methods
- (NSObject<BBResponder> *)defaultResponder;
- (void)setDefaultResponder:(NSObject<BBResponder> *)newResponder;
- (NSObject<BBResponder> *)responderForPath:(NSString *)thePath;
- (void)setResponder:(NSObject<BBResponder> *)theResponder forPath:(NSString *)thePath;
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6
- (BBResponseHandler)defaultHandler;
- (void)setDefaultHandler:(BBResponseHandler)theHandler;
- (BBResponseHandler)handlerForPath:(NSString *)thePath;
- (void)setHandlerForPath:(NSString *)thePath handler:(BBResponseHandler)theHandler;
#endif

@end
