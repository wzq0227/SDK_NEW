//
//  UIImage+RenderFunc.m
//  ULife3.5
//
//  Created by Goscam on 2018/6/6.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import "UIImage+RenderFunc.h"

@implementation UIImage (RenderFunc)

+ (instancetype)imageWithPath:(NSString*)path{
    
    return [UIImage  initImmediateLoadWithContentsOfFile: path];
}

+ (instancetype)imageWithName:(NSString*)name{
    
    NSString *imgPath = [[NSBundle mainBundle] pathForResource:name ofType:nil];
    
    if ( !imgPath ) {
        imgPath = [[NSBundle mainBundle] pathForResource:name ofType:@"png"];
    }

    if (!imgPath) {
        imgPath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%@@2x" ,name] ofType:@"png"];
    }
    
    if (!imgPath) {
        imgPath = [[NSBundle mainBundle] pathForResource:name ofType:@"jpg"];
    }
    
    return [UIImage  initImmediateLoadWithContentsOfFile: imgPath];
}



+ (UIImage*) initImmediateLoadWithContentsOfFile:(NSString*)path {
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:path];
    CGImageRef imageRef = [image CGImage];
    CGRect rect = CGRectMake(0.f, 0.f, CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
    CGContextRef bitmapContext = CGBitmapContextCreate(NULL,
                                                       rect.size.width,
                                                       rect.size.height,
                                                       CGImageGetBitsPerComponent(imageRef),
                                                       CGImageGetBytesPerRow(imageRef),
                                                       CGImageGetColorSpace(imageRef),
                                                       kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little
                                                       );
    //kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little are the bit flags required so that the main thread doesn't have any conversions to do.
    
    CGContextDrawImage(bitmapContext, rect, imageRef);
    CGImageRef decompressedImageRef = CGBitmapContextCreateImage(bitmapContext);
    UIImage* decompressedImage = [[UIImage alloc] initWithCGImage: decompressedImageRef scale:2.0 orientation:UIImageOrientationUp];

    CGImageRelease(decompressedImageRef);
    CGContextRelease(bitmapContext);
    
    return decompressedImage;
}

@end
