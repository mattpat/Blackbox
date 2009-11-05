//
//  BBDirectoryResponder.h
//  Blackbox
//
//  Created by Matt Patenaude on 12/8/08.
//  Copyright 2008 Matt Patenaude. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BBResponder.h"


@interface BBDirectoryResponder : NSObject<BBResponder> {
	NSString *directoryPath;
	BOOL allowDirectoryListing;
}

// Initializers
- (id)initWithDirectory:(NSString *)pathToDirectory;
+ (id)directoryResponderWithDirectory:(NSString *)pathToDirectory;

// Properties
- (BOOL)allowDirectoryListing;
- (void)setAllowDirectoryListing:(BOOL)shouldAllow;

// Methods
- (void)handleRequest:(BBRequest *)theRequest;

@end
