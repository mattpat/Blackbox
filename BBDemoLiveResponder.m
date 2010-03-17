//
//  BBDemoLiveResponder.m
//  Blackbox
//
//  Created by Matt Patenaude on 3/16/10.
//  Copyright 2010 Matt Patenaude. All rights reserved.
//

#import "BBDemoLiveResponder.h"
#import "BBRequest.h"


@implementation BBDemoLiveResponder

#pragma mark Responder methods (BBResponder)
- (void)handleRequest:(BBRequest *)theRequest
{
	// we'll respond with the contents of the textbox
	NSString *result = [NSString stringWithFormat:@"<h1>Blackbox Demo</h1><p>%@</p>", [theTextBox string]];
	
	[theRequest setResponseContentType:@"text/html"];
	[theRequest setResponseString:result];
}

@end
