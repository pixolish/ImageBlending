//
//  Cvision.h
//  DynamicSelection
//
//  Created by Somnath Mukherjee on 08/09/2014
//  Copyright (c) 2014 Somnath. All rights reserved.
//

#ifndef DynamicSelection_Cvision_h
#define DynamicSelection_Cvision_h

//#import <opencv2/opencv.hpp>
#import <opencv2/highgui/cap_ios.h>
#import <opencv2/core/core_c.h>
#import <opencv2/highgui/highgui_c.h>
#import <opencv2/core/core.hpp>
#import <opencv2/highgui/highgui.hpp>
#import <opencv2/imgproc/imgproc.hpp>
#import <opencv2/core/mat.hpp>
//#import <opencv2/>

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#endif
 //namespace cv;

@interface Cvision : NSObject

-(UIImage*) poissonImage:(UIImage*)src11:(UIImage*)src22:(UIImage*)srcmask;

-(void) getGradientx:(IplImage*)img:(IplImage*)gx;
-(void) getGradienty:(IplImage*)img:(IplImage*)gy;
-(void) lapx:(IplImage*)img:(IplImage*)gxx;
-(void) lapy:(IplImage*)img:(IplImage*)gyy;
-(void) dst:(double*)gtest:(double*)gfinal:(int) h:(int) w;
-(void) idst:(double*)gtest:(double*)gfinal:(int) h:(int) w;
-(void) transpose:(double*)mat:(double*)mat_t:(int) h:(int) w;
//-(void) poisson_solver:(IplImage*)img:(IplImage*)gxx: (IplImage*)gyy:(cv::Mat) result;

-(IplImage*)normal_blend:(IplImage*)I:(IplImage*)mask:(IplImage*)wmask;


@end