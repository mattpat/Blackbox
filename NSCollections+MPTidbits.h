//
//  NSCollections+MPTidbits.h
//  MPTidbits
//
//  Created by Matt Patenaude on 12/22/08.
//  Copyright 2008 Matt Patenaude. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSArray(MPTidbits)

- (BOOL)isEmpty;

@end

@interface NSDictionary(MPTidbits)

- (BOOL)isEmpty;
- (BOOL)containsKey:(NSString *)aKey;
- (BOOL)containsKey:(NSString *)aKey allowEmptyValue:(BOOL)allowEmpty;

@end

