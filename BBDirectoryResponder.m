//
//  BBDirectoryResponder.m
//  Blackbox
//
//  Created by Matt Patenaude on 9/7/10.
//  Copyright 2010 Matt Patenaude.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "BBDirectoryResponder.h"
#import "BBRequest.h"


@implementation BBDirectoryResponder

#pragma mark Deallocator
- (void)dealloc
{
	[rootPath release];
	[super dealloc];
}

#pragma mark Properties
- (NSString *)rootPath
{
	return rootPath;
}
- (void)setRootPath:(NSString *)thePath
{
	if (rootPath)
	{
		[rootPath release];
		rootPath = nil;
	}
	rootPath = [thePath copy];
}

#pragma mark Responder methods
- (void)handleRequest:(BBRequest *)theRequest
{
	if (!rootPath)
	{
		[theRequest setResponseStatusCode:404];
		[theRequest setResponseContentType:@"text/html"];
		[theRequest setResponseString:[self HTMLFileNotFoundResponseForPath:[theRequest fullPath]]];
		return;
	}
	
	NSString *realPath = [[rootPath stringByAppendingPathComponent:[theRequest fullPath]] stringByResolvingSymlinksInPath];
	
	BOOL isDir = NO;
	if ([[NSFileManager defaultManager] fileExistsAtPath:realPath isDirectory:&isDir])
	{
		if (isDir)
		{
			CFURLRef redirURL = CFURLCreateCopyAppendingPathComponent(NULL, (CFURLRef)[theRequest requestURL], CFSTR(""), false);
			NSString *redirString = [(NSURL *)redirURL absoluteString];
			CFRelease(redirURL);
			
			if (![[[theRequest requestURL] absoluteString] isEqualToString:redirString])
			{
				[theRequest setResponseStatusCode:301];
				[theRequest setResponseHeaderValue:redirString forHeader:@"Location"];
				return;
			}
			
			NSString *indexPath = [self pathToIndexForDirectory:realPath];
			if (indexPath)
				[theRequest respondWithFile:indexPath];
			else
			{
				[theRequest setResponseContentType:@"text/html"];
				[theRequest setResponseString:[self HTMLDirectoryListingForPath:realPath requestPath:[theRequest fullPath]]];
			}
		}
		else
		{
			if ([self allowAccessToPath:realPath])
				[theRequest respondWithFile:realPath];
			else
			{
				[theRequest setResponseStatusCode:403];
				[theRequest setResponseContentType:@"text/html"];
				[theRequest setResponseString:[self HTMLForbiddenResponseForPath:[theRequest fullPath]]];
			}
		}
	}
	else
	{
		[theRequest setResponseStatusCode:404];
		[theRequest setResponseContentType:@"text/html"];
		[theRequest setResponseString:[self HTMLFileNotFoundResponseForPath:[theRequest fullPath]]];
	}
}

#pragma mark Overridable methods for customization
- (NSString *)pathToIndexForDirectory:(NSString *)thePath
{
	return nil;
}
- (NSString *)HTMLDirectoryListingForPath:(NSString *)thePath requestPath:(NSString *)requestPath
{
	NSMutableString *result = [NSMutableString stringWithFormat:@"<h1>Directory Listing: %@</h1>\n<ul>\n", requestPath];
	
	NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:thePath error:NULL];
	for (NSString *file in files)
	{
		if ([self allowAccessToPath:[thePath stringByAppendingPathComponent:file]])
			[result appendFormat:@"\t<li><a href=\"%@\">%@</a></li>\n", file, file];
	}
	
	[result appendString:@"</ul>"];
	return result;
}
- (NSString *)HTMLFileNotFoundResponseForPath:(NSString *)thePath
{
	return @"<h1>404 File Not Found</h1>";
}
- (NSString *)HTMLForbiddenResponseForPath:(NSString *)thePath
{
	return @"<h1>403 Forbidden</h1>";
}
- (BOOL)allowAccessToPath:(NSString *)thePath
{
	return (![[thePath lastPathComponent] hasPrefix:@"."]);
}

@end
