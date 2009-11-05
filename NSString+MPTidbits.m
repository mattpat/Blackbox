//
//  NSString+MPTidbits.m
//  MPTidbits
//
//  Created by Matt Patenaude on 12/22/08.
//  Copyright 2008 Matt Patenaude. All rights reserved.
//

#import "NSString+MPTidbits.h"


@implementation NSString(MPTidbits)

- (BOOL)isEmpty
{
	return [self isEmptyIgnoringWhitespace:YES];
}
- (BOOL)isEmptyIgnoringWhitespace:(BOOL)ignoreWhitespace
{
	NSString *toCheck = (ignoreWhitespace) ? [self stringByTrimmingWhitespace] : self;
	return [toCheck isEqualToString:@""];
}
- (NSString *)stringByTrimmingWhitespace
{
	return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

@end

@implementation NSMutableString(MPTidbits)

- (void)trimCharactersInSet:(NSCharacterSet *)aCharacterSet
{
	// trim front
	NSRange frontRange = NSMakeRange(0, 1);
	while ([aCharacterSet characterIsMember:[self characterAtIndex:0]])
		[self deleteCharactersInRange:frontRange];
	
	// trim back
	while ([aCharacterSet characterIsMember:[self characterAtIndex:([self length] - 1)]])
		[self deleteCharactersInRange:NSMakeRange(([self length] - 1), 1)];
}
- (void)trimWhitespace
{
	[self trimCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

@end

