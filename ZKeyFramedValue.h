//
//  KeyFramedValue.h
//  Speed
//
//  Created by Kaz Hoshino on 4/14/09.
//  Copyright 2009 Electricwoods LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

//
//	KeyFramedValue
//

@interface ZKeyFramedValue : NSObject
{
	float duration;
	NSValue *value;
}
+ (id)keyFramedValue:(NSValue *)aValue duration:(float)aDuration;
- (id)initWithValue:(NSValue *)aValue duration:(float)aDuration;
@property float duration;
@property (retain) NSValue *value;
@end

