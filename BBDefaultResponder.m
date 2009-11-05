//
//  BBDefaultResponder.m
//  Blackbox
//
//  Created by Matt Patenaude on 11/28/08.
//  Copyright 2008 Matt Patenaude. All rights reserved.
//

#import "BBDefaultResponder.h"
#import "BBRequest.h"


@implementation BBDefaultResponder

- (void)handleRequest:(BBRequest *)theRequest
{
	[theRequest setResponseString:@"HI THERE :D File not found."];
	[theRequest setResponseStatusCode:404];
	[theRequest sendResponse];
}

@end
