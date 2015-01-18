//
//  ViewController.h
//  DynamicSelection
//
//  Created by Somnath Mukherjee on 08/09/2014
//  Copyright (c) 2014 Somnath. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NextLayer.h"


@interface ViewController : UIViewController<UIGestureRecognizerDelegate>
{
    UIImageView *staticBG, *overlayView, *previewView;
    UIImage *backupImage;
    CGContextRef contextMarker;
    CGPoint beginPoint, lastPoint, prevPoint;
    float scalingFactor;
}

@end
