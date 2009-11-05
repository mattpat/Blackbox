//
//  NSString+MPTidbits.h
//  MPTidbits
//
//  Created by Matt Patenaude on 12/22/08.
//  Copyright 2008 Matt Patenaude. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString(MPTidbits)

- (BOOL)isEmpty;
- (BOOL)isEmptyIgnoringWhitespace:(BOOL)ignoreWhitespace;
- (NSString *)stringByTrimmingWhitespace;

@end

@interface NSMutableString(MPTidbits)

- (void)trimCharactersInSet:(NSCharacterSet *)aCharacterSet;
- (void)trimWhitespace;

@end
