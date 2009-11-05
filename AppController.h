//
//  AppController.h
//  Blackbox
//
//  Created by Matt Patenaude on 11/26/08.
//  Copyright 2008 Matt Patenaude. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Blackbox/Blackbox.h>


@interface AppController : NSObject {
	IBOutlet NSTextField *portField;
	
	BBServer *server;
}

- (IBAction)startServer:(id)sender;
- (IBAction)stopServer:(id)sender;

@end
