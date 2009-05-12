//
//  KeyFrameValue.m
//
//  Created by Kazuya Hoshino on 5/4/09.
//  Copyright 2009 Electricwoods LLC. All rights reserved.
//

#import "ZKeyFramedValue.h"


@implementation ZKeyFramedValue
@synthesize duration;
@synthesize value;

+ (id)keyFramedValue:(NSValue *)aValue duration:(float)aDuration
{
	return [[[ZKeyFramedValue alloc] initWithValue:aValue duration:(float)aDuration] autorelease];
}

- (id)initWithValue:(NSValue *)aValue duration:(float)aDuration
{
	if (self = [super init]) {
		duration = aDuration;
		value = [aValue retain];
	}
	return self;
}

- (void) dealloc
{
	[value release];
	[super dealloc];
}

@end
