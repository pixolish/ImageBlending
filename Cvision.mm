//
//  Cvision.cpp
//  DynamicSelection
//
//  Created by Somnath Mukherjee on 08/09/2014
//  Copyright (c) 2014 Somnath. All rights reserved//

#include "Cvision.h"
#include <opencv2/core/core_c.h>
#include <opencv2/highgui/highgui_c.h>
#include <opencv/cv.h>
#include <opencv/cxcore.h>
#include <opencv/highgui.h>



using namespace std;
using namespace cv;

#define pi 3.1416


@implementation Cvision;

-(void) getGradientx:(IplImage*) img:(IplImage*) gx
{
	int w = img->width;
	int h = img->height;
	int channel = img->nChannels;
    
	cvZero( gx );
	for(int i=0;i<h;i++)
		for(int j=0;j<w;j++)
			for(int c=0;c<channel;++c)
			{
				CV_IMAGE_ELEM(gx,float,i,j*channel+c) =
                (float)CV_IMAGE_ELEM(img,uchar,i,(j+1)*channel+c) - (float)CV_IMAGE_ELEM(img,uchar,i,j*channel+c);
			}
}
-(void)getGradienty:(IplImage*) img:(IplImage*) gy
{
	int w = img->width;
	int h = img->height;
	int channel = img->nChannels;
    
	cvZero( gy );
	for(int i=0;i<h;i++)
		for(int j=0;j<w;j++)
			for(int c=0;c<channel;++c)
			{
				CV_IMAGE_ELEM(gy,float,i,j*channel+c) =
                (float)CV_IMAGE_ELEM(img,uchar,(i+1),j*channel+c) - (float)CV_IMAGE_ELEM(img,uchar,i,j*channel+c);
                
			}
}



-(void) lapx:(IplImage*)img:(IplImage*)gxx
{
	int w = img->width;
	int h = img->height;
	int channel = img->nChannels;
    
	cvZero( gxx );
	for(int i=0;i<h;i++)
		for(int j=0;j<w-1;j++)
			for(int c=0;c<channel;++c)
			{
				CV_IMAGE_ELEM(gxx,float,i,(j+1)*channel+c) =
                (float)CV_IMAGE_ELEM(img,float,i,(j+1)*channel+c) - (float)CV_IMAGE_ELEM(img,float,i,j*channel+c);
			}
}
-(void) lapy:(IplImage*)img:(IplImage*)gyy
{
	int w = img->width;
	int h = img->height;
	int channel = img->nChannels;
    
	cvZero( gyy );
	for(int i=0;i<h-1;i++)
		for(int j=0;j<w;j++)
			for(int c=0;c<channel;++c)
			{
				CV_IMAGE_ELEM(gyy,float,i+1,j*channel+c) =
                (float)CV_IMAGE_ELEM(img,float,(i+1),j*channel+c) - (float)CV_IMAGE_ELEM(img,float,i,j*channel+c);
                
			}
}

-(void) dst:(double*) gtest:(double*)gfinal:(int) h:(int) w

{
    
	int k,r,z;
	unsigned long int idx;
    
    cv::Mat temp (2*h+2,1,CV_32F);
    cv::Mat res(h,1,CV_32F);
    
	Mat planes[] = {Mat_<float>(temp), Mat::zeros(temp.size(), CV_32F)};
    
	Mat complex1;
	int p=0;
	for(int i=0;i<w;i++)
	{
		temp.at<float>(0,0) = 0.0;
		
		for(int j=0,r=1;j<h;j++,r++)
		{
			idx = j*w+i;
			temp.at<float>(r,0) = gtest[idx];
		}
        
		temp.at<float>(h+1,0)=0.0;
        
		for(int j=h-1, r=h+2;j>=0;j--,r++)
		{
			idx = j*w+i;
			temp.at<float>(r,0) = -1*gtest[idx];
		}
		
		merge(planes, 2, complex1);
        
		dft(complex1,complex1,0,0);
        
		Mat planes1[] = {Mat::zeros(complex1.size(), CV_32F), Mat::zeros(complex1.size(), CV_32F)};
		
		// planes1[0] = Re(DFT(I)), planes1[1] = Im(DFT(I))
		split(complex1, planes1);
        
		std::complex<double> two_i = std::sqrt(std::complex<double>(-1));
        
		double fac = -2*imag(two_i);
        
		for(int c=1,z=0;c<h+1;c++,z++)
		{
			res.at<float>(z,0) = planes1[1].at<float>(c,0)/fac;
		}
        
		for(int q=0,z=0;q<h;q++,z++)
		{
			idx = q*w+p;
			gfinal[idx] =  res.at<float>(z,0);
		}
		p++;
	}
    
	temp.release();
	res.release();
	planes[0].release();
	planes[1].release();
    
}

-(void) idst:(double*)gtest:(double*)gfinal:(int) h:(int) w
{
	int nn = h+1;
	unsigned long int idx;
    [self dst:gtest:gfinal:h:w];
	for(int  i= 0;i<h;i++)
		for(int j=0;j<w;j++)
		{
			idx = i*w + j;
			gfinal[idx] = (double) (2*gfinal[idx])/nn;
		}
    
}
-(void) transpose:(double*)mat:(double*) mat_t:(int) h:(int) w
{
    
	Mat tmp = Mat(h,w,CV_32FC1);
	int p =0;
	unsigned long int idx;
	for(int i = 0 ; i < h;i++)
	{
		for(int j = 0 ; j < w; j++)
		{
            
			idx = i*(w) + j;
			tmp.at<float>(i,j) = mat[idx];
		}
	}
	Mat tmp_t = tmp.t();
    
	for(int i = 0;i < tmp_t.size().height; i++)
		for(int j=0;j<tmp_t.size().width;j++)
		{
			idx = i*tmp_t.size().width + j;
			mat_t[idx] = tmp_t.at<float>(i,j);
		}
    
	tmp.release();
    
}
-(void)poisson_solver:(IplImage*)img: (IplImage*)gxx:(IplImage*)gyy:(cv::Mat) result
{
    
	int w = img->width;
	int h = img->height;
	int channel = img->nChannels;
    
	unsigned long int idx,idx1;
    
	IplImage *lap  = cvCreateImage(cvGetSize(img), 32, 1);
    
	for(int i =0;i<h;i++)
		for(int j=0;j<w;j++)
			CV_IMAGE_ELEM(lap,float,i,j)=CV_IMAGE_ELEM(gyy,float,i,j)+CV_IMAGE_ELEM(gxx,float,i,j);
    
	Mat bound(img);
    
	for(int i =1;i<h-1;i++)
		for(int j=1;j<w-1;j++)
		{
			bound.at<uchar>(i,j) = 0.0;
		}
	
	double *f_bp = new double[h*w];
    
    
	for(int i =1;i<h-1;i++)
		for(int j=1;j<w-1;j++)
		{
			idx=i*w + j;
			f_bp[idx] = -4*(int)bound.at<uchar>(i,j) + (int)bound.at<uchar>(i,(j+1)) + (int)bound.at<uchar>(i,(j-1))
            + (int)bound.at<uchar>(i-1,j) + (int)bound.at<uchar>(i+1,j);
		}
	
    
	Mat diff = Mat(h,w,CV_32FC1);
	for(int i =0;i<h;i++)
	{
		for(int j=0;j<w;j++)
		{
			idx = i*w+j;
			diff.at<float>(i,j) = (CV_IMAGE_ELEM(lap,float,i,j) - f_bp[idx]);
		}
	}
    
	cvReleaseImage(&lap);
    
	double *gtest = new double[(h-2)*(w-2)];
	for(int i = 0 ; i < h-2;i++)
	{
		for(int j = 0 ; j < w-2; j++)
		{
			idx = i*(w-2) + j;
			gtest[idx] = diff.at<float>(i+1,j+1);
			
		}
	}
    
	diff.release();
	///////////////////////////////////////////////////// Find DST  /////////////////////////////////////////////////////
    
	double *gfinal = new double[(h-2)*(w-2)];
	double *gfinal_t = new double[(h-2)*(w-2)];
	double *denom = new double[(h-2)*(w-2)];
	double *f3 = new double[(h-2)*(w-2)];
	double *f3_t = new double[(h-2)*(w-2)];
	double *img_d = new double[(h)*(w)];
    
	[self dst:gtest:gfinal:h-2:w-2];
    
	[self transpose:gfinal:gfinal_t:h-2:w-2 ];
    
	[self dst:gfinal_t:gfinal:w-2:h-2];
    
	[self transpose:gfinal:gfinal_t:w-2:h-2];
    
	int cx=1;
	int cy=1;
    
	for(int i = 0 ; i < w-2;i++,cy++)
	{
		for(int j = 0,cx = 1; j < h-2; j++,cx++)
		{
			idx = j*(w-2) + i;
			denom[idx] = (float) 2*cos(pi*cy/( (double) (w-1))) - 2 + 2*cos(pi*cx/((double) (h-1))) - 2;
			
		}
	}
    
	for(idx = 0 ; idx < (w-2)*(h-2) ;idx++)
	{
		gfinal_t[idx] = gfinal_t[idx]/denom[idx];
	}
    
    
	[self idst:gfinal_t:f3:h-2:w-2];
  
 
	[self transpose:f3:f3_t:h-2:w-2];
    
	[self idst:f3_t:f3:w-2:h-2];
 
	[self transpose:f3:f3_t:w-2:h-2];
    
	for(int i = 0 ; i < h;i++)
	{
		for(int j = 0 ; j < w; j++)
		{
			idx = i*w + j;
			img_d[idx] = (double)CV_IMAGE_ELEM(img,uchar,i,j);
		}
	}
	for(int i = 1 ; i < h-1;i++)
	{
		for(int j = 1 ; j < w-1; j++)
		{
			idx = i*w + j;
			img_d[idx] = 0.0;
		}
	}
	int id1,id2;
	for(int i = 1,id1=0 ; i < h-1;i++,id1++)
	{
		for(int j = 1,id2=0 ; j < w-1; j++,id2++)
		{
			idx = i*w + j;
			idx1= id1*(w-2) + id2;
			img_d[idx] = f3_t[idx1];
		}
	}
	
	for(int i = 0 ; i < h;i++)
	{
		for(int j = 0 ; j < w; j++)
		{
			idx = i*w + j;
			if(img_d[idx] < 0.0)
				result.at<uchar>(i,j) = 0;
			else if(img_d[idx] > 255.0)
				result.at<uchar>(i,j) = 255.0;
			else
				result.at<uchar>(i,j) = img_d[idx];	
		}
	}
    
	delete [] gfinal;
	delete [] gfinal_t;
	delete [] denom;
	delete [] f3;
	delete [] f3_t;
	delete [] img_d;
	delete [] gtest;
	delete [] f_bp;
    
}





-(cv::Mat)cvMatWithImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to backing data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

- (UIImage *)imageWithCVMat:(const cv::Mat&)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize() * cvMat.total()];
    
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                     // Width
                                        cvMat.rows,                                     // Height
                                        8,                                              // Bits per component
                                        8 * cvMat.elemSize(),                           // Bits per pixel
                                        cvMat.step[0],                                  // Bytes per row
                                        colorSpace,                                     // Colorspace
                                        kCGImageAlphaNone | kCGBitmapByteOrderDefault,  // Bitmap info flags
                                        provider,                                       // CGDataProviderRef
                                        NULL,                                           // Decode
                                        false,                                          // Should interpolate
                                        kCGRenderingIntentDefault);                     // Intent
    
    UIImage *image = [[UIImage alloc] initWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return image;
}


//================Convert==========

- (IplImage *)CreateIplImageFromUIImage:(UIImage *)image {
    // Getting CGImage from UIImage
    CGImageRef imageRef = image.CGImage;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    // Creating temporal IplImage for drawing
    IplImage *iplimage = cvCreateImage(cvSize(image.size.width,image.size.height), IPL_DEPTH_8U, 4 );
    // Creating CGContext for temporal IplImage
    CGContextRef contextRef = CGBitmapContextCreate(
                                                    iplimage->imageData, iplimage->width, iplimage->height,
                                                    iplimage->depth, iplimage->widthStep,
                                                    colorSpace, kCGImageAlphaPremultipliedLast|kCGBitmapByteOrderDefault
                                                    );
    // Drawing CGImage to CGContext
    CGContextDrawImage(
                       contextRef,
                       CGRectMake(0, 0, image.size.width, image.size.height),
                       imageRef
                       );
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);
    
    // Creating result IplImage
    IplImage *ret = cvCreateImage(cvGetSize(iplimage), IPL_DEPTH_8U, 3);
    cvCvtColor(iplimage, ret, CV_RGBA2BGR);
    cvReleaseImage(&iplimage);
    
    return ret;
}

//----


- (UIImage *)UIImageFromIplImage:(IplImage *)image {
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    // Allocating the buffer for CGImage
    NSData *data =
    [NSData dataWithBytes:image->imageData length:image->imageSize];
    CGDataProviderRef provider =
    CGDataProviderCreateWithCFData((CFDataRef)data);
    // Creating CGImage from chunk of IplImage
    CGImageRef imageRef = CGImageCreate(
                                        image->width, image->height,
                                        image->depth, image->depth * image->nChannels, image->widthStep,
                                        colorSpace, kCGImageAlphaNone|kCGBitmapByteOrderDefault,
                                        provider, NULL, false, kCGRenderingIntentDefault
                                        );
    // Getting UIImage from CGImage
    UIImage *ret = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    return ret;
}




//====

-(UIImage*) poissonImage:(UIImage*)src11:(UIImage*)src22:(UIImage*)srcmask
{
   
    
    IplImage* src=[self CreateIplImageFromUIImage:src11];
    IplImage* src2=[self CreateIplImageFromUIImage:src22];
    IplImage* mask =[self CreateIplImageFromUIImage:srcmask];
    IplImage *mask2 =cvCreateImage(cvGetSize(mask),8,1);
    cvCvtColor(mask,mask2,CV_BGR2GRAY);
    cvThreshold(mask2,mask2,0,255,CV_THRESH_BINARY);
    
    printf("Image-description....sourceimage-height%d-width%d-depth%d-----src2-%d-%d-%d-----mask-%d-%d-%d--",src->height,src->width,src->nChannels,src2->height,src2->width,src2->nChannels,mask2->height,mask2->width,mask2->nChannels);
    
    IplImage* result=cvCreateImage(cvGetSize(mask),8,4);
    
   IplImage* result1=  [self normal_blend:src:src2:mask2];

    
    cvCvtColor(result1,result,CV_BGR2RGBA);
    
    
    
    //c("Image",matsrc1);
    //cv::add (matsrc1,matsrc2,rtesult);
    UIImage *final =[self UIImageFromIplImage:result];
                     
    
    
    return final;

}


//=========

-(IplImage*) normal_blend:(IplImage*)I:(IplImage*)mask:(IplImage*)wmask
{
    
	unsigned long int idx;
    
	IplImage *grx  = cvCreateImage(cvGetSize(I), 32, 3);
	IplImage *gry  = cvCreateImage(cvGetSize(I), 32, 3);
    
	IplImage *sgx  = cvCreateImage(cvGetSize(mask), 32, 3);
	IplImage *sgy  = cvCreateImage(cvGetSize(mask), 32, 3);
    
	IplImage *ero  = cvCreateImage(cvGetSize(I), 8, 1);
	IplImage *res  = cvCreateImage(cvGetSize(I), 8, 3);
    
	cvZero(res);
    
	int w = I->width;
	int h = I->height;
	int channel = I->nChannels;
    
	int w1 = wmask->width;
	int h1 = wmask->height;
	int channel1 = wmask->nChannels;
    
	[self getGradientx:I:grx];
	[self getGradienty:I:gry];
    
    [self getGradientx:mask:sgx];
	[self getGradienty:mask:sgy];
    
	
	
    
	cvErode(wmask,ero,NULL,3);
    
	IplImage* smask = cvCreateImage(cvGetSize(ero),32,1);
	cvConvertScale(ero,smask,1.0/255.0,0.0);
    
	IplImage* srx32 = cvCreateImage(cvGetSize(res),32,3);
	cvConvertScale(res,srx32,1.0/255.0,0.0);
    
	IplImage* sry32 = cvCreateImage(cvGetSize(res),32,3);
	cvConvertScale(res,sry32,1.0/255.0,0.0);
    
	
	
	
		for(int i=0;i < h; i++)
			for(int j=0; j < w; j++)
				for(int c=0;c<channel;++c)
				{
					if(abs(CV_IMAGE_ELEM(sgx,float,i,j*channel+c) - CV_IMAGE_ELEM(sgy,float,i,j*channel+c)) >
                       abs(CV_IMAGE_ELEM(grx,float,i,j*channel+c) - CV_IMAGE_ELEM(gry,float,i,j*channel+c)))
					{
                        
						CV_IMAGE_ELEM(srx32,float,i,j*channel+c) = CV_IMAGE_ELEM(sgx,float,i,j*channel+c)
                        * CV_IMAGE_ELEM(smask,float,i,j);
						CV_IMAGE_ELEM(sry32,float,i,j*channel+c) = CV_IMAGE_ELEM(sgy,float,i,j*channel+c)
                        * CV_IMAGE_ELEM(smask,float,i,j);
					}
					else
					{
						CV_IMAGE_ELEM(srx32,float,i,j*channel+c) = CV_IMAGE_ELEM(grx,float,i,j*channel+c)
                        * CV_IMAGE_ELEM(smask,float,i,j);
						CV_IMAGE_ELEM(sry32,float,i,j*channel+c) = CV_IMAGE_ELEM(gry,float,i,j*channel+c)
                        * CV_IMAGE_ELEM(smask,float,i,j);
					}
	
                }
	cvReleaseImage(&smask);
	cvReleaseImage(&sgx);
	cvReleaseImage(&sgy);
    
	cvNot(ero,ero);
    
	IplImage* smask1 = cvCreateImage(cvGetSize(ero),32,1);
	cvConvertScale(ero,smask1,1.0/255.0,0.0);
    
	IplImage* grx32 = cvCreateImage(cvGetSize(res),32,3);
	cvConvertScale(res,grx32,1.0/255.0,0.0);
    
	IplImage* gry32 = cvCreateImage(cvGetSize(res),32,3);
	cvConvertScale(res,gry32,1.0/255.0,0.0);
    
	for(int i=0;i < h; i++)
		for(int j=0; j < w; j++)
			for(int c=0;c<channel;++c)
			{
				CV_IMAGE_ELEM(grx32,float,i,j*channel+c) =
                (CV_IMAGE_ELEM(grx,float,i,j*channel+c)*CV_IMAGE_ELEM(smask1,float,i,j));
				CV_IMAGE_ELEM(gry32,float,i,j*channel+c) =
                (CV_IMAGE_ELEM(gry,float,i,j*channel+c)*CV_IMAGE_ELEM(smask1,float,i,j));
			}
    
	cvReleaseImage(&smask1);
	cvReleaseImage(&grx);
	cvReleaseImage(&gry);
	cvReleaseImage(&ero);
    
    
	IplImage* fx = cvCreateImage(cvGetSize(res),32,3);
	IplImage* fy = cvCreateImage(cvGetSize(res),32,3);
    
	for(int i=0;i < h; i++)
		for(int j=0; j < w; j++)
			for(int c=0;c<channel;++c)
			{
				CV_IMAGE_ELEM(fx,float,i,j*channel+c) =
                (CV_IMAGE_ELEM(grx32,float,i,j*channel+c)+CV_IMAGE_ELEM(srx32,float,i,j*channel+c));
				CV_IMAGE_ELEM(fy,float,i,j*channel+c) =
                (CV_IMAGE_ELEM(gry32,float,i,j*channel+c)+CV_IMAGE_ELEM(sry32,float,i,j*channel+c));
			}
    
   
    
	cvReleaseImage(&srx32);
	cvReleaseImage(&grx32);
	cvReleaseImage(&sry32);
	cvReleaseImage(&gry32);
	cvReleaseImage(&res);
    
	IplImage *gxx  = cvCreateImage(cvGetSize(I), 32, 3);
	IplImage *gyy  = cvCreateImage(cvGetSize(I), 32, 3);
    
                    [self lapx :fx:gxx];
                    [self lapy:fy:gyy];
    
    
	cvReleaseImage(&fx);
	cvReleaseImage(&fy);
    
	IplImage *rx_channel = cvCreateImage(cvGetSize(I), IPL_DEPTH_32F, 1 );
	IplImage *gx_channel = cvCreateImage(cvGetSize(I), IPL_DEPTH_32F, 1 );
	IplImage *bx_channel = cvCreateImage(cvGetSize(I), IPL_DEPTH_32F, 1 );
    
	cvCvtPixToPlane(gxx, rx_channel, gx_channel, bx_channel,0);
	cvReleaseImage(&gxx);
    
	IplImage *ry_channel = cvCreateImage(cvGetSize(I), IPL_DEPTH_32F, 1 );
	IplImage *gy_channel = cvCreateImage(cvGetSize(I), IPL_DEPTH_32F, 1 );
	IplImage *by_channel = cvCreateImage(cvGetSize(I), IPL_DEPTH_32F, 1 );
    
	cvCvtPixToPlane(gyy, ry_channel, gy_channel, by_channel,0);
    
	cvReleaseImage(&gyy);
    
	IplImage *r_channel = cvCreateImage(cvGetSize(I), 8, 1 );
	IplImage *g_channel = cvCreateImage(cvGetSize(I), 8, 1 );
	IplImage *b_channel = cvCreateImage(cvGetSize(I), 8, 1 );
    
	cvCvtPixToPlane(I, r_channel, g_channel, b_channel,0);
    
	Mat resultr = Mat(h,w,CV_8UC1);
	Mat resultg = Mat(h,w,CV_8UC1);
	Mat resultb = Mat(h,w,CV_8UC1);
    
	clock_t tic = clock();
    
    //cvShowImage("ResultB",b_channel);
    
                    [self poisson_solver:r_channel:rx_channel: ry_channel:resultr];
                [self poisson_solver:g_channel:gx_channel:gy_channel:resultg ];
                    [self poisson_solver:b_channel:bx_channel:by_channel:resultb];
    
    
	clock_t toc = clock();
    
	printf("Execution time: %f seconds\n", (double)(toc - tic) / CLOCKS_PER_SEC);
    
	IplImage *final = cvCreateImage(cvGetSize(I), 8, 3 );
    
	for(int i=0;i<h;i++)
		for(int j=0;j<w;j++)
		{
			CV_IMAGE_ELEM(final,uchar,i,j*3+0) = resultr.at<uchar>(i,j);
			CV_IMAGE_ELEM(final,uchar,i,j*3+1) = resultg.at<uchar>(i,j);
			CV_IMAGE_ELEM(final,uchar,i,j*3+2) = resultb.at<uchar>(i,j);
		}
    
	resultr.release();
	resultg.release();
	resultb.release();
    
	cvReleaseImage(&r_channel);
	cvReleaseImage(&rx_channel);
	cvReleaseImage(&ry_channel);
	cvReleaseImage(&g_channel);
	cvReleaseImage(&gx_channel);
	cvReleaseImage(&gy_channel);
	cvReleaseImage(&b_channel);
	cvReleaseImage(&bx_channel);
	cvReleaseImage(&by_channel);
    
	return final;
                
    
}


@end


