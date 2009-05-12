//
//  ZAnimatableValue.h
//
//  Created by Kaz Yoshikawa on 5/4/09.
//  Copyright 2009 Electricwoods LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZKeyFramedValue.h"


/*

	ZAnimatableValue
	
	What is it?
	-----------
	Animatable value is designed for implementing variables that changing it's
	value depending on which time it was observed.
	

	How to use it?
	--------------
	For example, if you are implementing CGPoint that changes its position
	from (0, 50) to (-100, 200) for the next 5 seconds.
	
		AnimatablePointValue *point;
		point = [ZAnimatableValue animatablePointValue:CGPointMake(0.0f, 50.0f)];
		[point appendAnimatablePointValue:CGPointMake(-50.0f, 200.0f) duration:5.0f];


	Verification
	------------
	You can check that it's value is keep changing for the next 5 seconds by
	writing following code.
	
		NSTimeInterval timeup = [NSDate timeIntervalSinceReferenceDate] + 7.0f;
		while ([NSDate timeIntervalSinceReferenceDate] < timeup) {
			NSLog(@"position = %@", NSStringFromCGPoint([point pointValue]));
			[NSThread sleepForTimeInterval:0.1];
		}

	
	Architecture
	------------
	

	
	Supported Type
	--------------
	• float
	• double
	• CGPoint
	• CGSize
	• CGRect
	• NSRange
	
	But you can implement your own custom data type by subclassing AnimatableValue.
	Here is an example of extending 'YourData'.  Since AnimatableValue base
	class does not know how to 

	struct YourData {
		float firstData;
		float secondData;
	};
	typedef struct YourData YourData;

	@interface ZAnimatableYourData : ZAnimatableValue
	{
	}
	- (id)initWithYourData:(YourDataType)aValue;
	- (YourDataType)yourData;
	- (void)setYourData:(YourDataType)aValue;
	- (void)appendAnimatableYourData:(YourDataType)aValue duration:(float)aDuration;
	- (NSValue *)interpolateValueAtTime:(float)time duration:(float)duration fromValue:(NSValue *)fromValue toValue:(NSValue *)toValue;


	License
	-------
	The MIT License

	Copyright (c) 2009 Electricwoods LLC

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
	THE SOFTWARE.

*/

@class ZAnimatableValue;


//
//	HSBAColor
//
struct HSBAColor
{
	float hue;
	float saturation;
	float brightness;
	float alpha;
};
typedef struct HSBAColor HSBAColor;

//
//
//

@protocol ZAnimatableValueDelegate <NSObject>

- (void)animatableValueDidFinishedAnimating:(ZAnimatableValue *)aValue;

@end


//
//	ZAnimatableValue
//

@interface ZAnimatableValue : NSObject
{
	NSMutableArray *keyFramedValues;
	bool animating;
	float timestamp;
	float animatingTime;
	NSValue *currentValue;
	id <ZAnimatableValueDelegate> delegate;
}
@property (retain) id <ZAnimatableValueDelegate> delegate;

+ (float)intervalSinceReferenceTime;
+ (id)animatableFloatValue:(float)aValue;
+ (id)animatablePointValue:(CGPoint)aValue;
+ (id)animatableSizeValue:(CGSize)aValue;
+ (id)animatableRectValue:(CGRect)aValue;
+ (id)animatableRangeValue:(NSRange)aValue;
+ (id)animatableHSBAColorValue:(HSBAColor)aValue;

- (id)initWithValue:(NSValue *)aValue;
- (NSValue *)value;
- (void)setValue:(NSValue *)aValue;
- (void)appendAnimatableValue:(NSValue *)aValue duration:(float)duration;
- (NSValue *)interpolateValueAtTime:(float)time duration:(float)duration fromValue:(NSValue *)fromValue toValue:(NSValue *)toValue;
- (float)duration;

- (id <ZAnimatableValueDelegate>) delegate;
- (void)setDelegate:(id <ZAnimatableValueDelegate>)aDelegate;

- (void)startAnimating;
- (void)pauseAnimating;
- (void)cancelAnimating;

@end

//
//	ZAnimatableFloatValue
//

@interface ZAnimatableFloatValue : ZAnimatableValue
{
}
- (id)initWithFloatValue:(float)value;
- (float)floatValue;
- (void)setFloatValue:(float)aValue;
- (void)appendAnimatableFloatValue:(float)aValue duration:(float)aDuration;
- (NSValue *)interpolateValueAtTime:(float)time duration:(float)duration fromValue:(NSValue *)fromValue toValue:(NSValue *)toValue;

@end

//
//	ZAnimatablePointValue
//

@interface ZAnimatablePointValue : ZAnimatableValue
{
}
- (id)initWithPointValue:(CGPoint)value;
- (CGPoint)pointValue;
- (void)setPointValue:(CGPoint)aValue;
- (void)appendAnimatablePointValue:(CGPoint)aValue duration:(float)aDuration;
- (NSValue *)interpolateValueAtTime:(float)time duration:(float)duration fromValue:(NSValue *)fromValue toValue:(NSValue *)toValue;

@end

//
//	ZAnimatableSizeValue
//

@interface ZAnimatableSizeValue : ZAnimatableValue
{
}
- (id)initWithSizeValue:(CGSize)aValue;
- (CGSize)sizeValue;
- (void)setSizeValue:(CGSize)aValue;
- (void)appendAnimatableSizeValue:(CGSize)aValue duration:(float)aDuration;
- (NSValue *)interpolateValueAtTime:(float)time duration:(float)duration fromValue:(NSValue *)fromValue toValue:(NSValue *)toValue;

@end

//
//	ZAnimatableRectValue
//

@interface ZAnimatableRectValue : ZAnimatableValue
{
}
- (id)initWithRectValue:(CGRect)aValue;
- (CGRect)rectValue;
- (void)setRectValue:(CGRect)aValue;
- (void)appendAnimatableRectValue:(CGRect)aValue duration:(float)aDuration;
- (NSValue *)interpolateValueAtTime:(float)time duration:(float)duration fromValue:(NSValue *)fromValue toValue:(NSValue *)toValue;

@end

//
//	ZAnimatableRangeValue
//

@interface ZAnimatableRangeValue : ZAnimatableValue
{
}
- (id)initWithRangeValue:(NSRange)aValue;
- (NSRange)rangeValue;
- (void)setRangeValue:(NSRange)aValue;
- (void)appendAnimatableRangeValue:(NSRange)aValue duration:(float)aDuration;
- (NSValue *)interpolateValueAtTime:(float)time duration:(float)duration fromValue:(NSValue *)fromValue toValue:(NSValue *)toValue;

@end

//
//	ZAnimatableHSBAColorValue
//

@interface ZAnimatableHSBAColor : ZAnimatableValue
{
}
- (id)initWithHSBAColor:(HSBAColor)aValue;
- (HSBAColor)HSBAColor;
- (void)setHSBAColor:(HSBAColor)aValue;
- (void)appendAnimatableHSBAColor:(HSBAColor)aValue duration:(float)aDuration;
- (NSValue *)interpolateValueAtTime:(float)time duration:(float)duration fromValue:(NSValue *)fromValue toValue:(NSValue *)toValue;

@end






