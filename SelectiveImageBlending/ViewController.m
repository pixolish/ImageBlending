//
//  ViewController.m
//  DynamicSelection
//
//  Created by Somnath Mukherjee on 08/09/2014
//  Copyright (c) 2014 Somnath. All rights reserved.
//

#import "ViewController.h"

#define SOURCE_IMAGE_NAME @"birds.jpg"
//#define SOURCE_IMAGE_NAME @"src_img01.jpg"
//#define SOURCE_IMAGE_NAME @"IMG_5216.jpg"

#define DESATINATION_IMAGE_NAME @"cruise.jpg"
//#define DESATINATION_IMAGE_NAME @"IMG_6852.JPG"



@interface ViewController ()

@end

@implementation ViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    scalingFactor = 1.0;
    
    staticBG = [[UIImageView alloc] initWithImage:[UIImage imageNamed:SOURCE_IMAGE_NAME]];
    staticBG.frame = CGRectMake(0, 0, 320, 400);
    [self.view addSubview:staticBG];
    
    overlayView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"92970.png"]];
    overlayView.frame = CGRectMake(0, 0, 320, 400);
    [self.view addSubview:overlayView];
    overlayView.hidden = YES;
    
    previewView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:SOURCE_IMAGE_NAME]]; // specific image not important
    previewView.frame = CGRectMake(100, 320, 160, 160);
    [self.view addSubview:previewView];
    previewView.hidden = YES;
    
    UIButton *selectBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    selectBtn.frame = CGRectMake(40, 440, 60, 30);
    [selectBtn setTitle:@"Select" forState:UIControlStateNormal];
    [selectBtn addTarget:self action:@selector(applyEffect) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:selectBtn];
    
    UIButton *gotobtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    gotobtn.frame = CGRectMake(40, 480, 60, 30);
    [gotobtn setTitle:@"Next" forState:UIControlStateNormal];
    [gotobtn addTarget:self action:@selector(gotoNextLayer) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:gotobtn];
    
    staticBG.image = [self resample :staticBG.image];
    [self fitFrameToImage :staticBG :staticBG.image :0 :0];
    
    backupImage = [[UIImage alloc] initWithCGImage:[staticBG.image CGImage]];
    
    overlayView.image = [self resampleOverlay :overlayView.image];
    [self fitFrameToImage :overlayView :overlayView.image :0 :0];
}


- (void)gotoNextLayer
{
    NextLayer *new = [[NextLayer alloc] init];
    new.destinationName = DESATINATION_IMAGE_NAME;
    
    [self presentViewController:new animated:YES completion:Nil];
    [new.foregroundView setImage:previewView.image];
    [new.foregroundView setBackgroundColor: [UIColor clearColor]];
    [new fitForeground];
    //[new release];
}

- (UIImage *)resample :(UIImage *)inputImage
{
    int w = inputImage.size.width;
    int h = inputImage.size.height;
    
   	int destWidth = 480, destHeight = 480, width, height;
	if(w > h)
    {
		width  = destWidth;
		height = h * destWidth / w;
	} else {
		height = destHeight;
        width  = w * destWidth / h;
	}
    
    height -= height % 8;
    width  -= width  % 8;
    
    CGSize newSize = CGSizeMake(width, height);
    UIGraphicsBeginImageContext(newSize);
    CGContextSetInterpolationQuality(UIGraphicsGetCurrentContext(), kCGInterpolationHigh);
    CGContextSetAllowsAntialiasing(UIGraphicsGetCurrentContext(), true);
    CGContextSetShouldAntialias(UIGraphicsGetCurrentContext(), true);
    CGContextSetShouldSmoothFonts(UIGraphicsGetCurrentContext(), true);
    [inputImage drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newimage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // Invert the red and blue channel
    CFDataRef pixelData = CGDataProviderCopyData(CGImageGetDataProvider([newimage CGImage]));
    unsigned char *baseImage = (unsigned char *)CFDataGetBytePtr(pixelData);
    size_t bytesPerRow = CGImageGetBytesPerRow([newimage CGImage]);
    unsigned char *output_buffer = (unsigned char *)malloc(height * bytesPerRow);
    
    for (int i=0; i<height; i++)
    {
        long step = i * bytesPerRow;
        for (int j=0; j<bytesPerRow; j+=4)
        {
            output_buffer[step + j+0] = baseImage[step + j+2];
            output_buffer[step + j+1] = baseImage[step + j+1];
            output_buffer[step + j+2] = baseImage[step + j+0];
            output_buffer[step + j+3] = 255;
        }
    }
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast;
    CGContextRef context = CGBitmapContextCreate(output_buffer, width, height, 8, bytesPerRow, colorSpaceRef, bitmapInfo);
    CGImageRef imageRef = CGBitmapContextCreateImage (context);
    newimage = [UIImage imageWithCGImage:imageRef];
    CGColorSpaceRelease(colorSpaceRef);
    CGContextRelease(context);
    CFRelease(imageRef);
    
    free(output_buffer);
    
    return newimage;
}

- (UIImage *)resampleOverlay :(UIImage *)inputImage
{
    int width = staticBG.image.size.width;
    int height = staticBG.image.size.height;
    
    CGSize newSize = CGSizeMake(width, height);
    UIGraphicsBeginImageContext(newSize);
    CGContextSetInterpolationQuality(UIGraphicsGetCurrentContext(), kCGInterpolationHigh);
    CGContextSetAllowsAntialiasing(UIGraphicsGetCurrentContext(), true);
    CGContextSetShouldAntialias(UIGraphicsGetCurrentContext(), true);
    CGContextSetShouldSmoothFonts(UIGraphicsGetCurrentContext(), true);
    [inputImage drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newimage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newimage;
}


- (void)fitFrameToImage :(UIImageView *)view :(UIImage *)image :(float)xScreenBuff :(float)yScreenBuff
{
    int height = image.size.height;
    int width = image.size.width;
    CGRect inputRect = view.frame;
    
    // Calculate screen-space coordinates according to aspect ratio and resize frame accordingly
    if (height > width)
    {
        scalingFactor = view.frame.size.height / height;
        float xStart = (height - width) / 2 * scalingFactor;
        float yStart = view.frame.origin.y;
        float xWidth = width * scalingFactor;
        float yHeight = view.frame.size.height;
        view.frame = CGRectMake(xStart + xScreenBuff, yStart + yScreenBuff, xWidth, yHeight);
    }
    
    else
    {
        scalingFactor = view.frame.size.width / width;
        float xStart = view.frame.origin.x;
        float yStart = (width - height) / 2 * scalingFactor;
        float xWidth = view.frame.size.width;
        float yHeight = height * scalingFactor;
        view.frame = CGRectMake(xStart + xScreenBuff, yStart + yScreenBuff, xWidth, yHeight);
    }
    
    CGRect rect;
    rect.origin.y = (inputRect.size.height - view.frame.size.height) / 2; // Forced repositioning
    rect.origin.x = (inputRect.size.width - view.frame.size.width) / 2;   // ^ to middle of screen
    rect.size.height = view.frame.size.height;
    rect.size.width = view.frame.size.width;
    
    view.frame = rect;
    view.backgroundColor = [UIColor redColor]; // Precautionary step - There should be NO VISIBLE BLACK color
}



- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    beginPoint = [touch locationInView:staticBG];
    prevPoint = beginPoint;
    /*contextMarker = UIGraphicsGetCurrentContext();
    CGContextSetRGBStrokeColor(contextMarker, 255.0, 255.0, 255.0, 1.0);
    CGContextSetRGBFillColor(contextMarker, 255.0, 255.0, 0.0, 1.0);
    CGContextSetLineJoin(contextMarker, kCGLineJoinRound);
    CGContextSetLineWidth(contextMarker, 8.0);*/
    
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    // Do necessary calculations for converting screen space touch co-ordinates to image space
    CGPoint imgCurrPnt, imgPrevPoint, imgBeginPnt;
    UITouch *touch = [touches anyObject];
    CGPoint currentPoint = [touch locationInView:staticBG];
    imgCurrPnt.x = currentPoint.x / scalingFactor;
    imgCurrPnt.y = currentPoint.y / scalingFactor;
    imgBeginPnt.x = beginPoint.x / scalingFactor;
    imgBeginPnt.y = beginPoint.y / scalingFactor;
    imgPrevPoint.x = prevPoint.x / scalingFactor;
    imgPrevPoint.y = prevPoint.y / scalingFactor;
    
    // Do respective processing and create mask image
    UIGraphicsBeginImageContext(overlayView.image.size);
    [overlayView.image drawInRect:CGRectMake(0, 0, overlayView.image.size.width, overlayView.image.size.height)];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 1.0);
    CGContextBeginPath(context);
    UIColor *overlayColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.5f];
    CGContextSetFillColorWithColor(context, overlayColor.CGColor);
    CGContextMoveToPoint(context, imgCurrPnt.x, imgCurrPnt.y);
    CGContextSetRGBStrokeColor(context, 1, 1, 1, 0.5);
    CGContextAddLineToPoint(context, imgPrevPoint.x, imgPrevPoint.y);
    CGContextAddLineToPoint(context, imgBeginPnt.x, imgBeginPnt.y);
    CGPathDrawingMode mode = kCGPathFillStroke;
    CGContextClosePath(context);
    CGContextDrawPath(context, mode);
    
    overlayView.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // Do respective processing for display purpose - A backup for staticBG.image should be maintained
    UIGraphicsBeginImageContext(staticBG.image.size);
    [staticBG.image drawInRect:CGRectMake(0, 0, staticBG.image.size.width, staticBG.image.size.height)];
    
    CGContextRef context1 = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context1, 1.0);
    CGContextBeginPath(context1);
    CGContextSetFillColorWithColor(context1, overlayColor.CGColor);
    CGContextMoveToPoint(context1, imgCurrPnt.x, imgCurrPnt.y);
    CGContextSetRGBStrokeColor(context1, 1.0, 1.0, 1.0, 1.0);
    CGContextAddLineToPoint(context1, imgPrevPoint.x, imgPrevPoint.y);
    CGPathDrawingMode mode1 = kCGPathFillStroke;
    CGContextClosePath(context1);
    CGContextDrawPath(context1, mode1);
    
    staticBG.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //overlayView.hidden = NO;
    //staticBG.hidden = NO;
    prevPoint = currentPoint;
}

// Process the mask image to create a rectangle in image-space which will be used to crop out portions from original image
- (void)applyEffect
{
    CFDataRef maskPixelData = CGDataProviderCopyData(CGImageGetDataProvider([overlayView.image CGImage]));
    unsigned char *maskBuffer = (unsigned char *)CFDataGetBytePtr(maskPixelData);
    
    //CFDataRef originalPixelData = CGDataProviderCopyData(CGImageGetDataProvider([backupImage CGImage]));
    unsigned char *originalBuffer = [self getRGB:backupImage];
    
    size_t bytesPerRow = CGImageGetBytesPerRow([overlayView.image CGImage]);
    size_t height = CGImageGetHeight([overlayView.image CGImage]);
    size_t width = CGImageGetWidth([overlayView.image CGImage]);
    unsigned char *outputBuffer = (unsigned char *)malloc(height * bytesPerRow);
    
    int left = 9999, right = 0, top = 9999, bottom = 0;
    for (int i=0; i<height; i++)
    {
        long step = i * bytesPerRow;
        for (int j=0; j<bytesPerRow; j+=4)
        {
            
            if (maskBuffer[step + j] > 100) // find out white portions of the mask
            {
                if (j / 4 > right)
                    right = j / 4;
                
                if (i > bottom)
                    bottom = i;
                
                if (j / 4 < left)
                    left = j / 4;
                
                if (i < top)
                    top = i;
                
                outputBuffer[step + j+0] = originalBuffer[step + j+0];
                outputBuffer[step + j+1] = originalBuffer[step + j+1];
                outputBuffer[step + j+2] = originalBuffer[step + j+2];
                outputBuffer[step + j+3] = 255;
            }
            
            else // make the rest region transparent - alpha set to 0
            {
                outputBuffer[step + j+3] = 0;
            }
        }
    }
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast;
    CGContextRef context = CGBitmapContextCreate(outputBuffer, width, height, 8, bytesPerRow, colorSpaceRef, bitmapInfo);
    CGImageRef imageRef = CGBitmapContextCreateImage (context);
    UIImage *newimage = [UIImage imageWithCGImage:imageRef];
    CGColorSpaceRelease(colorSpaceRef);
    CGContextRelease(context);
    CFRelease(imageRef);
    CFRelease(maskPixelData);
    
    CGRect imageRect = CGRectMake(left, top, right - left, bottom - top);
    
    CGImageRef cropRef = CGImageCreateWithImageInRect([newimage CGImage], imageRect);
    UIImage *croppedImage = [UIImage imageWithCGImage:cropRef scale:newimage.scale orientation:newimage.imageOrientation];
    [previewView setImage:croppedImage];
    [previewView setContentMode:UIViewContentModeScaleAspectFit];
    previewView.hidden = NO;
    
    CFRelease(cropRef);
    free(outputBuffer);
}

// Getting RGB CORRECT buffer from UIImage
- (unsigned char *)getRGB :(UIImage *)inputImage
{
    CGImageRef imageRef = [inputImage CGImage];
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    NSUInteger bytesPerRow = CGImageGetBytesPerRow(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *buffer = (unsigned char*) malloc(height * width * 4);
    CGContextRef context = CGBitmapContextCreate(buffer, width, height,
                                                    8, bytesPerRow, colorSpace,
                                                    kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    
    return buffer;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
