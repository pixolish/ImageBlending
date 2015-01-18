//
//  NextLayer.m
//  DynamicSelection
//
//  Created by Somnath Mukherjee on 08/09/2014
//  Copyright (c) 2014 Somnath. All rights reserved.
//

#import "NextLayer.h"
#import "Cvision.h"

@interface NextLayer ()

@end

@implementation NextLayer

@synthesize foregroundView;
@synthesize destinationName;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    scalingFactor = 1.0;
    boxSize = 100;
    
    bgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:destinationName]];
    bgView.frame = CGRectMake(0, 0, 320, 400);
    [self.view addSubview:bgView];
    
    foregroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:destinationName]];
    foregroundView.frame = CGRectMake(100, 320, boxSize, boxSize);
    [self.view addSubview:foregroundView];
    [foregroundView setContentMode:UIViewContentModeScaleAspectFit];
    
    slider = [[UISlider alloc] initWithFrame:CGRectMake(40, 480, 200, 30)];
    [slider addTarget:self action:@selector(sliderAction) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:slider];
    slider.hidden = YES;
    
    UIButton *backBtn = [[UIButton alloc] initWithFrame:CGRectMake(275, 0, 35, 35)];
    [backBtn setTitle:@"Back" forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(I_iz_back) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:backBtn];
    
    UIButton *applyBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    applyBtn.frame = CGRectMake(60, 420, 80, 20);
    [applyBtn setTitle:@"Apply" forState:UIControlStateNormal];
    [applyBtn addTarget:self action:@selector(applyEnhanced) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:applyBtn];
    
    bgView.image = [self resample :bgView.image :480 :480 :true];
    scalingFactor = [self fitFrameToImage :bgView :bgView.image :0 :0];
    
    v = [[Cvision alloc] init];
}


- (UIImage *)resample :(UIImage *)inputImage :(size_t)destWidth :(size_t)destHeight :(bool)forceMultipleOf8
{
    int w = inputImage.size.width;
    int h = inputImage.size.height;
    
   	int width, height;
	if(w > h)
    {
		width  = destWidth;
		height = h * destWidth / w;
	} else {
		height = destHeight;
        width  = w * destWidth / h;
	}
    
    if (forceMultipleOf8) // prevent xzazzy
    {
        height -= height % 8;
        width  -= width  % 8;
    }
    
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
            output_buffer[step + j+0] = baseImage[step + j+2]; // Red
            output_buffer[step + j+1] = baseImage[step + j+1]; // Green
            output_buffer[step + j+2] = baseImage[step + j+0]; // Blue
            output_buffer[step + j+3] = baseImage[step + j+3];
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
    CFRelease(pixelData);
    
    free(output_buffer);
    
    return newimage;
}


- (float)fitFrameToImage :(UIImageView *)view :(UIImage *)image :(float)xScreenBuff :(float)yScreenBuff
{
    int height = image.size.height;
    int width = image.size.width;
    CGRect inputRect = view.frame;
    float scaleFactor;
    
    // Calculate screen-space coordinates according to aspect ratio and resize frame accordingly
    if (height > width)
    {
        scaleFactor = view.frame.size.height / height;
        float xStart = (height - width) / 2 * scaleFactor;
        float yStart = view.frame.origin.y;
        float xWidth = width * scaleFactor;
        float yHeight = view.frame.size.height;
        view.frame = CGRectMake(xStart + xScreenBuff, yStart + yScreenBuff, xWidth, yHeight);
    }
    
    else
    {
        scaleFactor = view.frame.size.width / width;
        float xStart = view.frame.origin.x;
        float yStart = (width - height) / 2 * scaleFactor;
        float xWidth = view.frame.size.width;
        float yHeight = height * scaleFactor;
        view.frame = CGRectMake(xStart + xScreenBuff, yStart + yScreenBuff, xWidth, yHeight);
    }
    
    CGRect rect;
    rect.origin.y = (inputRect.size.height - view.frame.size.height) / 2; // Forced repositioning
    rect.origin.x = (inputRect.size.width - view.frame.size.width) / 2;   // ^ to middle of screen
    rect.size.height = view.frame.size.height;
    rect.size.width = view.frame.size.width;
    
    view.frame = rect;
    view.backgroundColor = [UIColor redColor]; // Precautionary step - There should be NO VISIBLE BLACK color
    
    return scaleFactor;
}

- (void)fitForeground
{
    previewScale = [self fitFrameToImage :foregroundView :foregroundView.image :0 :0];
}


- (void)sliderAction
{
    boxSize = 80 + slider.value * 100;
    CGRect rect = CGRectMake(foregroundPoint.x - boxSize / 2, foregroundPoint.y - boxSize / 2, boxSize, boxSize);
    foregroundView.frame = rect;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint beginPoint = [touch locationInView:self.view];
    
    float leftBound = foregroundView.frame.origin.x;
    float rightBound = foregroundView.frame.origin.x + foregroundView.frame.size.width;
    float upBound = foregroundView.frame.origin.y;
    float downBound = foregroundView.frame.origin.y + foregroundView.frame.size.height;
    
    CGRect rect = CGRectMake(beginPoint.x - foregroundView.frame.size.width / 2, beginPoint.y - foregroundView.frame.size.height / 2, foregroundView.frame.size.width, foregroundView.frame.size.height);
    
    if (beginPoint.x > leftBound && beginPoint.x < rightBound && beginPoint.y > upBound && beginPoint.y < downBound)
        foregroundView.frame = rect;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    foregroundPoint = [touch locationInView:self.view];
    
    CGRect rect = CGRectMake(foregroundPoint.x - foregroundView.frame.size.width / 2, foregroundPoint.y - foregroundView.frame.size.height / 2, foregroundView.frame.size.width, foregroundView.frame.size.height);
    foregroundView.frame = rect;
}


- (void)applyEffect
{
    UIGraphicsBeginImageContext(bgView.image.size);
    [bgView.image drawInRect:CGRectMake(0, 0, bgView.image.size.width, bgView.image.size.height)];
    
    CGRect imageRect = CGRectMake((foregroundView.frame.origin.x -  bgView.frame.origin.x) / scalingFactor, (foregroundView.frame.origin.y - bgView.frame.origin.y) / scalingFactor, foregroundView.image.size.width * previewScale / scalingFactor, foregroundView.image.size.height * previewScale / scalingFactor);
    [foregroundView.image drawInRect:imageRect];
    
    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    UIImageWriteToSavedPhotosAlbum(resultImage, nil, nil, nil);
}

- (void)applyEnhanced
{
    NSLog(@"processed");
    
    float maskHeight = foregroundView.image.size.height * previewScale / scalingFactor;
    float maskWidth = foregroundView.image.size.width * previewScale / scalingFactor;
    float left = (foregroundView.frame.origin.x - bgView.frame.origin.x) / scalingFactor;
    float right = left + maskWidth;
    float up = (foregroundView.frame.origin.y - bgView.frame.origin.y) / scalingFactor;
    float down = up + maskHeight;
    
    size_t height = CGImageGetHeight([bgView.image CGImage]);
    size_t width = CGImageGetWidth([bgView.image CGImage]);
    size_t bytesPerRow = CGImageGetBytesPerRow([bgView.image CGImage]);
    
    maskBuffer = (unsigned char *)malloc(height * bytesPerRow);;
    UIImage *sourceImage = [self resample:foregroundView.image :maskWidth :maskHeight :false];
    sourceImage = [self createSource :sourceImage :height :width :bytesPerRow :left :right :up :down];
    
    UIImage *result = [self poissonBlend :sourceImage :bgView.image];
    UIImage *maskimage = [self makeImageFromBuffer:maskBuffer :height :width :bytesPerRow];
    //[bgView setImage:maskimage];
    UIImage *result1 = [v poissonImage:bgView.image:sourceImage:maskimage ] ;
    [bgView setImage:result1];
     UIImageWriteToSavedPhotosAlbum(result1, nil, nil, nil);
    bgView.hidden = NO;
    foregroundView.hidden = YES;
    
    //[sourceImage release];
    //[maskImage release];
}

/* - (UIImage *)createMask :(UIImage *)sourceImage :(size_t)height :(size_t)width :(size_t)bytesPerRow :(float)left :(float)right :(float)up :(float)down
{
    CFDataRef pixelData = CGDataProviderCopyData(CGImageGetDataProvider([sourceImage CGImage]));
    unsigned char *sourceBuffer = (unsigned char *)CFDataGetBytePtr(pixelData);
    
    unsigned char *output_buffer = (unsigned char *)malloc(height * bytesPerRow);
    
    for (int i=0; i<height; i++)
    {
        long step = i * bytesPerRow;
        for (int j=0; j<bytesPerRow; j+=4)
        {
            if (i > up && i < down && j/4 > left && j/4 < right && sourceBuffer[step + j+3] == 255)
            {
                output_buffer[step + j+0] = 255; // Red
                output_buffer[step + j+1] = 255; // Green
                output_buffer[step + j+2] = 255; // Blue
            }
            else
            {
                output_buffer[step + j+0] = 0; // Red
                output_buffer[step + j+1] = 0; // Green
                output_buffer[step + j+2] = 0; // Blue
            }
            
            output_buffer[step + j+3] = 255;
        }
    }
    
    return [self makeImageFromBuffer:output_buffer :height :width :bytesPerRow];
}*/

- (UIImage *)createSource :(UIImage *)inputSource :(size_t)height :(size_t)width :(size_t)bytesPerRow :(float)left :(float)right :(float)up :(float)down
{
    CFDataRef pixelData = CGDataProviderCopyData(CGImageGetDataProvider([inputSource CGImage]));
    unsigned char *fg_buffer = (unsigned char *)CFDataGetBytePtr(pixelData);
    size_t fgBytesPerRow = CGImageGetBytesPerRow([inputSource CGImage]);
    
    unsigned char *buffer = (unsigned char *)malloc(height * bytesPerRow);
    
    for (int i=0; i<height; i++)
    {
        long step = i * bytesPerRow;
        int fgi = i - up;
        long fgStep = fgi * fgBytesPerRow;
        
        for (int j=0; j<bytesPerRow; j+=4)
        {
            int fgj = j - left * 4;
            fgj = 4 * (fgj / 4);
            
            if (i >= up && i <= down && j/4 >= left && j/4 <= right)
            {
                buffer[step + j+0] = fg_buffer[fgStep + fgj+0];
                buffer[step + j+1] = fg_buffer[fgStep + fgj+1];
                buffer[step + j+2] = fg_buffer[fgStep + fgj+2];
                buffer[step + j+3] = 255;
                
                if (fg_buffer[fgStep + fgj+3] == 0)
                {
                    maskBuffer[step + j+0] = 0;
                    maskBuffer[step + j+1] = 0;
                    maskBuffer[step + j+2] = 0;
                    maskBuffer[step + j+3] = 255;
                }
                else
                {
                    maskBuffer[step + j+0] = 255;
                    maskBuffer[step + j+1] = 255;
                    maskBuffer[step + j+2] = 255;
                    maskBuffer[step + j+3] = 255;
                }
            }
            
            else
            {
                buffer[step + j+0] = 0;   // Red
                buffer[step + j+1] = 0;   // Green
                buffer[step + j+2] = 0;   // Blue
                buffer[step + j+3] = 255; // Alpha
                
                maskBuffer[step + j+0] = 0;
                maskBuffer[step + j+1] = 0;
                maskBuffer[step + j+2] = 0;
                maskBuffer[step + j+3] = 255;
            }
        }
    }
    UIImage *newImage = [self makeImageFromBuffer:buffer :height :width :bytesPerRow];
    
    free(buffer);
    CFRelease(pixelData);
    
    return newImage;
}

- (UIImage *)makeImageFromBuffer :(unsigned char *)inputBuffer :(size_t)height :(size_t)width :(size_t)bytesPerRow
{
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast;
    CGContextRef context = CGBitmapContextCreate(inputBuffer, width, height, 8, bytesPerRow, colorSpaceRef, bitmapInfo);
    CGImageRef imageRef = CGBitmapContextCreateImage (context);
    UIImage *newimage = [UIImage imageWithCGImage:imageRef];
    CGColorSpaceRelease(colorSpaceRef);
    CGContextRelease(context);
    CFRelease(imageRef);
    
    return newimage;
}


- (UIImage *)poissonBlend :(UIImage *)sourceImage :(UIImage *)targetImage
{
    CFDataRef sourcePixelData = CGDataProviderCopyData(CGImageGetDataProvider([sourceImage CGImage]));
    unsigned char *sourceBuffer = (unsigned char *)CFDataGetBytePtr(sourcePixelData);
    
    CFDataRef targetPixelData = CGDataProviderCopyData(CGImageGetDataProvider([targetImage CGImage]));
    unsigned char *targetBuffer = (unsigned char *)CFDataGetBytePtr(targetPixelData);
    size_t height = CGImageGetHeight([targetImage CGImage]);
    size_t width = CGImageGetWidth([targetImage CGImage]);
    size_t bytesPerRow = CGImageGetBytesPerRow([targetImage CGImage]);
    
    unsigned char *output_buffer = (unsigned char *)malloc(height * bytesPerRow);
    
    double alpha;
    double den = 1;
    double A = width / den;
    int xPos = width / 2;
    int yPos = height / 2;
    
    for (int i=0; i<height; i++)
    {
        long step = i * bytesPerRow;
        for (int j=0; j<bytesPerRow; j+=4)
        {
            alpha = A * (exp(- 2 * (((pow((j/4 - xPos) / den, 2))) + ((pow((i - yPos) / den, 2))))));
            alpha = alpha > 1 ? 1 : alpha;
            
            if (maskBuffer[step + j] == 255)
            {
                output_buffer[step + j]   = targetBuffer[step + j+0] * alpha + sourceBuffer[step + j+0] * (1 - alpha);
                output_buffer[step + j+1] = targetBuffer[step + j+1] * alpha + sourceBuffer[step + j+1] * (1 - alpha);
                output_buffer[step + j+2] = targetBuffer[step + j+2] * alpha + sourceBuffer[step + j+2] * (1 - alpha);
            }
            else
            {
                output_buffer[step + j]   = targetBuffer[step + j];
                output_buffer[step + j+1] = targetBuffer[step + j+1];
                output_buffer[step + j+2] = targetBuffer[step + j+2];
            }
            output_buffer[step + j+3] = 255;
        }
    }
    UIImage *newImage = [self makeImageFromBuffer:output_buffer :height :width :bytesPerRow];
    
    free(output_buffer);
    
    return newImage;
}


// Dismiss current viewcontroller, return to main
- (void)I_iz_back
{
    NSLog(@"im back");
    
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

/*else
{
    output_buffer[step + j]   = 0;
    output_buffer[step + j+1] = 0;
    output_buffer[step + j+2] = 0;
    
    for(int k=i-1; k<=i+1; k++)
    {
        for (int l=j-1; l<=j+1; l++)
        {
            output_buffer[step + 4*(j/4)]   += sourceBuffer[step + 4*(j/4)]   - sourceBuffer[k*bytesPerRow + 4*(l/4)];
            output_buffer[step + 4*(j/4)+1] += sourceBuffer[step + 4*(j/4)+1] - sourceBuffer[k*bytesPerRow + 4*(l/4)+1];
            output_buffer[step + 4*(j/4)+2] += sourceBuffer[step + 4*(j/4)+2] - sourceBuffer[k*bytesPerRow + 4*(l/4)+2];
            
            if (maskBuffer[k*bytesPerRow + 4*(l/4)] == 0)
            {
                output_buffer[step + 4*(j/4)]   += targetBuffer[k*bytesPerRow + 4*(l/4)];
                output_buffer[step + 4*(j/4)+1] += targetBuffer[k*bytesPerRow + 4*(l/4)+1];
                output_buffer[step + 4*(j/4)+2] += targetBuffer[k*bytesPerRow + 4*(l/4)+2];
            }
            else
            {
                output_buffer[step + 4*(j/4)]   += output_buffer[k*bytesPerRow + 4*(l/4)];
                output_buffer[step + 4*(j/4)+1] += output_buffer[k*bytesPerRow + 4*(l/4)+1];
                output_buffer[step + 4*(j/4)+2] += output_buffer[k*bytesPerRow + 4*(l/4)+2];
            }
        }
    }
}*/
