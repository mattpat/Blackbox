//
//  BBRequest.h
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


// Functions
NSString *BBNormalizeHeaderName(NSString *headerName);
void BBParseQueryIntoDictionary(NSString *queryString, NSMutableDictionary *dict);
void BBParsePropertyListIntoDictionary(NSData *postData, NSMutableDictionary *dict);

// Forward declarations
@class BBServer;
@class BBConnection;

@interface BBRequest : NSObject {
	BBServer *server;
	BBConnection *connection;
	
	NSString *HTTPMethod;
	NSString *fullPath;
	NSString *relativePath;
	NSString *queryString;
	NSData *postData;
	NSMutableDictionary *getParams;
	NSMutableDictionary *postParams;
	
	NSData *responseData;
	NSMutableDictionary *responseHeaders;
	NSMutableDictionary *requestHeaders;
	NSInteger responseStatusCode;
	NSString *responseFilePath;
	
	BOOL useAsynchronousResponse;
}

// Initializers
- (id)initWithServer:(BBServer *)theServer connection:(BBConnection *)theConnection message:(CFHTTPMessageRef)theMessage asynchronous:(BOOL)async;

// Properties
- (NSString *)fullPath;
- (NSString *)relativePath;
- (NSString *)HTTPMethod;
- (NSData *)rawPostData;
- (NSString *)postString;
- (NSDictionary *)headers;
- (NSString *)queryString;
- (NSDictionary *)GETParameters;
- (NSDictionary *)POSTParameters;
- (NSInteger)responseStatusCode;
- (NSDictionary *)responseHeaders;
- (NSData *)responseData;
- (NSString *)responseFilePath;
- (BBConnection *)connection;

// Methods
- (NSString *)valueForHeader:(NSString *)theHeader;
- (NSString *)valueForResponseHeader:(NSString *)theHeader;
- (void)setResponseContentType:(NSString *)theContentType;
- (void)setResponseStatusCode:(NSInteger)statusCode;
- (void)setResponseHeaderValue:(NSString *)headerValue forHeader:(NSString *)headerName;
- (void)setResponseString:(NSString *)theString;
- (void)setResponseBody:(NSData *)theData;
- (void)respondWithFile:(NSString *)path;
- (void)sendResponse;	// asynchronous responses only!

@end
