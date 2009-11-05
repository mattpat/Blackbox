//
//  NSCollections+MPTidbits.m
//  MPTidbits
//
//  Created by Matt Patenaude on 12/22/08.
//  Copyright 2008 Matt Patenaude. All rights reserved.
//

#import "NSCollections+MPTidbits.h"
#import "NSString+MPTidbits.h"


@implementation NSArray(MPTidbits)

- (BOOL)isEmpty
{
	return ([self count] == 0);
}

@end

@implementation NSDictionary(MPTidbits)

- (BOOL)isEmpty
{
	return ([self count] == 0);
}
- (BOOL)containsKey:(NSString *)aKey
{
	return [self containsKey:aKey allowEmptyValue:YES];
}
- (BOOL)containsKey:(NSString *)aKey allowEmptyValue:(BOOL)allowEmpty
{
	BOOL keyExists = [[self allKeys] containsObject:aKey];
	if (keyExists)
	{
		if (allowEmpty)
			return YES;
		else
		{
			id obj = [self objectForKey:aKey];
			if ([obj isEqual:[NSNull null]])
				return NO;
			if ([obj respondsToSelector:@selector(isEmpty)] && [obj isEmpty])
				return NO;
			return YES;
		}
	}
	return NO;
}

@end

