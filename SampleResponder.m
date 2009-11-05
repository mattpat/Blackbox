//
//  SampleResponder.m
//  Blackbox
//
//  Created by Matt Patenaude on 12/8/08.
//  Copyright 2008 Matt Patenaude. All rights reserved.
//

#import "SampleResponder.h"


@implementation SampleResponder

- (void)handleRequest:(BBRequest *)theRequest
{
	[theRequest setResponseString:[NSString stringWithFormat:@"<p>This is a sample response to the relative path: %@</p>", [theRequest relativePath]]];
	[theRequest setResponseContentType:@"text/html"];
	[theRequest sendResponse];
}

@end
