//
//  BBDemoLiveResponder.h
//  Blackbox
//
//  Created by Matt Patenaude on 3/16/10.
//  Copyright 2010 Matt Patenaude. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BBResponder.h"


@interface BBDemoLiveResponder : NSObject<BBResponder> {
	IBOutlet NSTextView *theTextBox;
}

// Responder methods (BBResponder)
- (void)handleRequest:(BBRequest *)theRequest;

@end
