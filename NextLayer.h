//
//  NextLayer.h
//  SelectiveImageBlending
//
//  Created by Somnath Mukherjee on 08/09/2014
//  Copyright (c) 2014 Somnath. All rights reserved
//

#import <UIKit/UIKit.h>
#import "Cvision.h"

@interface NextLayer : UIViewController<UIGestureRecognizerDelegate>
{
    UIImageView *bgView;
    unsigned char *maskBuffer; //, *sourceImage;
    UISlider *slider;
    CGPoint foregroundPoint;
    
    float scalingFactor, boxSize, previewScale;
    Cvision *v;
}

- (void)fitForeground;

@property (nonatomic, strong) UIImageView *foregroundView;
@property (nonatomic, assign) float abcd;
@property (nonatomic, assign) NSString *destinationName;

@end
