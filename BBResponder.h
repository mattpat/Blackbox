/*
 *  BBResponder.h
 *  Blackbox
 *
 *  Created by Matt Patenaude on 11/28/08.
 *  Copyright 2008 Matt Patenaude. All rights reserved.
 *
 */

#import <Cocoa/Cocoa.h>

@class BBRequest;

@protocol BBResponder

- (void)handleRequest:(BBRequest *)theRequest;

@end