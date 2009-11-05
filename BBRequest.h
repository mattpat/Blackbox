//
//  BBRequest.h
//  Blackbox
//
//  Created by Matt Patenaude on 11/28/08.
//  Copyright 2008 Matt Patenaude. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NSString *BBNormalizeHeaderName(NSString *headerName);
void BBParseQueryIntoDictionary(NSString *queryString, NSMutableDictionary *dict);

@class BBServer;
@class BBConnection;

@interface BBRequest : NSObject {
	BBServer *server;
	BBConnection *connection;
	CFHTTPMessageRef request;
	NSString *fullPath;
	NSString *relativePath;
	NSString *queryString;
	NSMutableDictionary *getParams;
	NSMutableDictionary *postParams;
	
	NSData *responseData;
	NSMutableDictionary *responseHeaders;
	int responseStatusCode;
}

// Initializers
- (id)initWithServer:(BBServer *)theServer connection:(BBConnection *)theConnection message:(CFHTTPMessageRef)theMessage;

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

// Methods
- (void)setResponseContentType:(NSString *)theContentType;
- (void)setResponseStatusCode:(int)statusCode;
- (void)setResponseHeaderValue:(NSString *)headerValue forHeader:(NSString *)headerName;
- (void)setResponseString:(NSString *)theString;
- (void)setResponseBody:(NSData *)theData;
- (void)sendResponse;

// Private methods
- (void)_setRelativePath:(NSString *)newRelativePath;

@end
