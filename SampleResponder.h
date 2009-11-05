//
//  SampleResponder.h
//  Blackbox
//
//  Created by Matt Patenaude on 12/8/08.
//  Copyright 2008 Matt Patenaude. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Blackbox/Blackbox.h>


@interface SampleResponder : NSObject<BBResponder> {

}

- (void)handleRequest:(BBRequest *)theRequest;

@end
