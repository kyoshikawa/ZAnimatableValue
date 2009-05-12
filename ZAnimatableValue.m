//
//  AnimatableValue.m
//
//  Created by Kaz Yoshikawa on 4/13/09.
//  Copyright 2009 Electricwoods LLC. All rights reserved.
//

#import "ZAnimatableValue.h"
#import "ZKeyFramedValue.h"

NSTimeInterval gReferenceTime = 0.0;

//
//	interpolateValue
//

NS_INLINE float interpolateFloatValue(float time, float duration, float fromValue, float toValue)
{
	float ratio = (toValue - fromValue) / duration;
	return toValue - ((duration - time) * ratio);
} 

NS_INLINE double interpolateDoubleValue(float time, float duration, double fromValue, double toValue)
{
	double ratio = (toValue - fromValue) / duration;
	return toValue - ((duration - time) * ratio);
} 

//
//	AnimatableValue
//

@implementation ZAnimatableValue

+ (void)initialize;
{
	if (self == [ZAnimatableValue class]) {
		gReferenceTime = [NSDate timeIntervalSinceReferenceDate];
	}
}

+ (float)intervalSinceReferenceTime
{
	NSTimeInterval interval = [NSDate timeIntervalSinceReferenceDate] - gReferenceTime;
	return (float)interval;
}

+ (id)animatableFloatValue:(float)aValue
{
	return [[[ZAnimatableFloatValue alloc] initWithFloatValue:aValue] autorelease];
}

+ (id)animatablePointValue:(CGPoint)aValue
{
	return [[[ZAnimatablePointValue alloc] initWithPointValue:aValue] autorelease];
}

+ (id)animatableSizeValue:(CGSize)aValue
{
	return [[[ZAnimatableSizeValue alloc] initWithSizeValue:aValue] autorelease];
}

+ (id)animatableRectValue:(CGRect)aValue
{
	return [[[ZAnimatableRectValue alloc] initWithRectValue:aValue] autorelease];
}

+ (id)animatableRangeValue:(NSRange)aValue
{
	return [[[ZAnimatableRangeValue alloc] initWithRangeValue:aValue] autorelease];
}

+ (id)animatableHSBAColorValue:(HSBAColor)aValue
{
	return [[[ZAnimatableHSBAColor alloc] initWithHSBAColor:aValue] autorelease];
}

- (id)initWithValue:(NSValue *)aValue
{
	if (self = [super init]) {
		keyFramedValues = nil;
		animating = NO;
		timestamp = 0.0f;
		animatingTime = 0.0f;
		currentValue = [aValue retain];
		delegate = nil;
	}
	return self;
}

- (void) dealloc
{
	[currentValue release];
	[keyFramedValues release];
	[delegate release];
	[super dealloc];
}

- (NSValue *)value
{
	if (animating) {
		float now = [ZAnimatableValue intervalSinceReferenceTime];
		float elapseTime = (now - timestamp);
		animatingTime += elapseTime;
		timestamp = now;
		
		if (keyFramedValues) {
			int current = 0;
			for (current = 0 ; current < [keyFramedValues count] ; current++) {
				ZKeyFramedValue *keyFramedValue = [keyFramedValues objectAtIndex:current];
				float duration = [keyFramedValue duration];
				if (animatingTime < duration) {
					if (current > 0) {
						[keyFramedValues removeObjectsInRange:NSMakeRange(0, current)];
					}
					NSValue *value = [keyFramedValue value];
					return [self interpolateValueAtTime:animatingTime duration:duration fromValue:currentValue toValue:value];
				}
				animatingTime -= duration;
				[currentValue release];
				currentValue = [[keyFramedValue value] retain];
			}

			// this means all key frames are history, delete them
			[keyFramedValues release];
			keyFramedValues = nil;
			animatingTime = 0.0f;
			timestamp = 0.0f;
			animating = NO;
			return [[currentValue retain] autorelease];
		}
		animating = NO;
	}
	return [[currentValue retain] autorelease];
}

- (void)setValue:(NSValue *)aValue
{
	if (keyFramedValues) {
		[keyFramedValues release];
		keyFramedValues = nil;
	}

	if (currentValue != aValue) {
		[currentValue autorelease];
		currentValue = [aValue retain];
	}
	
	animatingTime = 0.0f;
	timestamp = 0.0f;
	animating = NO;

	[NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)scheduleAnimatingDidFinishedTimer
{
	if (animating) {
		float duration = [self duration];
		if (duration > 0.0f) {
			[self performSelector:@selector(animatingDidFinished) withObject:nil afterDelay:duration];
		}
	}
}

- (void)appendAnimatableValue:(NSValue *)aValue duration:(float)duration
{
	keyFramedValues = keyFramedValues ? keyFramedValues : [[NSMutableArray alloc] init];
	[keyFramedValues addObject:[ZKeyFramedValue keyFramedValue:aValue duration:duration]];
	if (!animating) {
		[self startAnimating];
	}
	else {
		[NSObject cancelPreviousPerformRequestsWithTarget:self];
		[self scheduleAnimatingDidFinishedTimer];
	}
}

- (NSValue *)interpolateValueAtTime:(float)time duration:(float)duration fromValue:(NSValue *)fromValue toValue:(NSValue *)toValue;
{
	NSAssert(NO, @"Subclasses should override");
	return nil;
}

- (float)duration
{
	float duration = 0.0f;
	if (keyFramedValues == nil) return duration;
	for (ZKeyFramedValue *keyFramedValue in keyFramedValues) {
		duration += [keyFramedValue duration];
	}
	duration -= animatingTime;
	return duration;
}

- (id <ZAnimatableValueDelegate>) delegate
{
	return delegate;
}

- (void)setDelegate:(id <ZAnimatableValueDelegate>)aDelegate
{
	if (delegate != aDelegate) {
		[delegate release];
		delegate = [aDelegate retain];
		[self scheduleAnimatingDidFinishedTimer];
	}
}

- (void)animatingDidFinished
{
	if (delegate) {
		[delegate animatableValueDidFinishedAnimating:self];
	}
}

- (void)startAnimating
{
	if (!animating && keyFramedValues) {
		animating = YES;
		timestamp = [ZAnimatableValue intervalSinceReferenceTime];
		[self scheduleAnimatingDidFinishedTimer];
	}
}

- (void)pauseAnimating
{
	if (animating) {
		[NSObject cancelPreviousPerformRequestsWithTarget:self];
		float interval = [ZAnimatableValue intervalSinceReferenceTime] - timestamp;
		animatingTime += interval;
		animating = NO;
	}
}

- (void)cancelAnimating
{
	if (animating) {
		timestamp = 0.0f;
		animatingTime = 0.0f;
		animating = NO;
		[NSObject cancelPreviousPerformRequestsWithTarget:self];
	}
	[keyFramedValues release];
	keyFramedValues = nil;
}

@end

//
//	AnimatableFloatValue
//

@implementation ZAnimatableFloatValue

- (id)initWithFloatValue:(float)aValue
{
	NSValue *value = [NSValue value:&aValue withObjCType:@encode(float)];
	if (self = [super initWithValue:value]) {
	}
	return self;
}

- (float)floatValue
{
	NSValue *valueObject = [self value];

	float value;
	[valueObject getValue:&value];
	return value;
}

- (void)setFloatValue:(float)aValue
{
	NSValue *value = [NSValue value:&aValue withObjCType:@encode(float)];
	[self setValue:value];
}

- (void)appendAnimatableFloatValue:(float)aValue duration:(float)aDuration;
{
	NSValue *value = [NSValue value:&aValue withObjCType:@encode(float)];
	[self appendAnimatableValue:value duration:aDuration];
}

- (NSValue *)interpolateValueAtTime:(float)time duration:(float)duration fromValue:(NSValue *)fromValue toValue:(NSValue *)toValue
{
	float value1;
	float value2;
	[fromValue getValue:&value1];
	[toValue getValue:&value2];

	float result = interpolateFloatValue(time, duration, value1, value2);
	return [NSValue valueWithBytes:&result objCType:@encode(float)];
}

@end

//
//	AnimatablePointValue
//

@implementation ZAnimatablePointValue

- (id)initWithPointValue:(CGPoint)aValue
{
	NSValue *value = [NSValue value:&aValue withObjCType:@encode(CGPoint)];
	if (self = [super initWithValue:value]) {
	}
	return self;
}


- (CGPoint)pointValue
{
	NSValue *value = [self value];

	CGPoint point;
	[value getValue:&point];
	return point;
}

- (void)setPointValue:(CGPoint)aValue
{
	[self setValue:[NSValue valueWithCGPoint:aValue]];
}

- (void)appendAnimatablePointValue:(CGPoint)aValue duration:(float)aDuration
{
	[self appendAnimatableValue:[NSValue valueWithCGPoint:aValue] duration:aDuration];
}

- (NSValue *)interpolateValueAtTime:(float)time duration:(float)duration fromValue:(NSValue *)fromValue toValue:(NSValue *)toValue
{
	CGPoint value1;
	CGPoint value2;
	[fromValue getValue:&value1];
	[toValue getValue:&value2];

	float x = interpolateFloatValue(time, duration, value1.x, value2.x);
	float y = interpolateFloatValue(time, duration, value1.y, value2.y);
	CGPoint result = CGPointMake(x, y);
	return [NSValue valueWithBytes:&result objCType:@encode(CGPoint)];
}

@end


//
//	AnimatableSizeValue
//

@implementation ZAnimatableSizeValue

- (id)initWithSizeValue:(CGSize)aValue
{
	NSValue *value = [NSValue value:&aValue withObjCType:@encode(CGSize)];
	if (self = [super initWithValue:value]) {
	}
	return self;
}

- (CGSize)sizeValue
{
	NSValue *value = [self value];

	CGSize size;
	[value getValue:&size];
	return size;
}

- (void)setSizeValue:(CGSize)aValue
{
	[self setValue:[NSValue valueWithCGSize:aValue]];
}

- (void)appendAnimatableSizeValue:(CGSize)aValue duration:(float)aDuration
{
	[self appendAnimatableValue:[NSValue valueWithCGSize:aValue] duration:aDuration];
}

- (NSValue *)interpolateValueAtTime:(float)time duration:(float)duration fromValue:(NSValue *)fromValue toValue:(NSValue *)toValue
{
	CGSize value1;
	CGSize value2;
	[fromValue getValue:&value1];
	[toValue getValue:&value2];

	float w = interpolateFloatValue(time, duration, value1.width, value2.width);
	float h = interpolateFloatValue(time, duration, value1.height, value2.height);
	CGSize result = CGSizeMake(w, h);
	return [NSValue valueWithBytes:&result objCType:@encode(CGSize)];
}

@end

//
//	AnimatableRectValue
//

@implementation ZAnimatableRectValue

- (id)initWithRectValue:(CGRect)aValue
{
	NSValue *value = [NSValue value:&aValue withObjCType:@encode(CGRect)];
	if (self = [super initWithValue:value]) {
	}
	return self;
}

- (CGRect)rectValue
{
	NSValue *value = [self value];

	CGRect rect;
	[value getValue:&rect];
	return rect;
}

- (void)setRectValue:(CGRect)aValue
{
	[self setValue:[NSValue valueWithCGRect:aValue]];
}

- (void)appendAnimatableRectValue:(CGRect)aValue duration:(float)aDuration
{
	[self appendAnimatableValue:[NSValue valueWithCGRect:aValue] duration:aDuration];
}

- (NSValue *)interpolateValueAtTime:(float)time duration:(float)duration fromValue:(NSValue *)fromValue toValue:(NSValue *)toValue
{
	CGRect value1;
	CGRect value2;
	[fromValue getValue:&value1];
	[toValue getValue:&value2];

	float x = interpolateFloatValue(time, duration, value1.origin.x, value2.origin.x);
	float y = interpolateFloatValue(time, duration, value1.origin.y, value2.origin.y);
	float w = interpolateFloatValue(time, duration, value1.size.width, value2.size.width);
	float h = interpolateFloatValue(time, duration, value1.size.height, value2.size.height);
	CGRect result = CGRectMake(x, y, w, h);
	return [NSValue valueWithBytes:&result objCType:@encode(CGRect)];
}

@end

//
//	AnimatableRangeValue
//

@implementation ZAnimatableRangeValue

- (id)initWithRangeValue:(NSRange)aValue
{
	NSValue *value = [NSValue value:&aValue withObjCType:@encode(NSRange)];
	if (self = [super initWithValue:value]) {
	}
	return self;
}

- (NSRange)rangeValue
{
	NSValue *value = [self value];

	NSRange range;
	[value getValue:&range];
	return range;
}

- (void)setRangeValue:(NSRange)aValue
{
	[self setValue:[NSValue valueWithRange:aValue]];
}

- (void)appendAnimatableRangeValue:(NSRange)aValue duration:(float)aDuration
{
	[self appendAnimatableValue:[NSValue valueWithRange:aValue] duration:aDuration];
}

- (NSValue *)interpolateValueAtTime:(float)time duration:(float)duration fromValue:(NSValue *)fromValue toValue:(NSValue *)toValue
{
	NSRange value1;
	NSRange value2;
	[fromValue getValue:&value1];
	[toValue getValue:&value2];

	NSUInteger location = interpolateFloatValue(time, duration, value1.location, value2.location);
	NSUInteger length = interpolateFloatValue(time, duration, value1.length, value2.length);
	NSRange result = NSMakeRange(location, length);
	return [NSValue valueWithBytes:&result objCType:@encode(NSRange)];
}

@end

//
//	AnimatableRangeValue
//

@implementation ZAnimatableHSBAColor

- (id)initWithHSBAColor:(HSBAColor)aValue
{
	NSValue *value = [NSValue value:&aValue withObjCType:@encode(HSBAColor)];
	if (self = [super initWithValue:value]) {
	}
	return self;
}

- (HSBAColor)HSBAColor
{
	NSValue *value = [self value];

	HSBAColor color;
	[value getValue:&color];
	return color;
}

- (void)setHSBAColor:(HSBAColor)aValue
{
	[self setValue:[NSValue value:&aValue withObjCType:@encode(HSBAColor)]];
}

- (void)appendAnimatableHSBAColor:(HSBAColor)aValue duration:(float)aDuration
{
	[self appendAnimatableValue:[NSValue value:&aValue withObjCType:@encode(HSBAColor)] duration:aDuration];
}

- (NSValue *)interpolateValueAtTime:(float)time duration:(float)duration fromValue:(NSValue *)fromValue toValue:(NSValue *)toValue
{
	HSBAColor value1;
	HSBAColor value2;
	[fromValue getValue:&value1];
	[toValue getValue:&value2];

	float h = interpolateFloatValue(time, duration, value1.hue, value2.hue);
	float s = interpolateFloatValue(time, duration, value1.saturation, value2.saturation);
	float b = interpolateFloatValue(time, duration, value1.brightness, value2.brightness);
	float a = interpolateFloatValue(time, duration, value1.alpha, value2.alpha);

	HSBAColor result = { h, s, b, a };
	return [NSValue valueWithBytes:&result objCType:@encode(HSBAColor)];
}

@end
