//
//  ShareWithFriendsViewController.m
//  ULife3.5
//
//  Created by zhuochuncai on 3/6/17.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "ShareWithFriendsViewController.h"
#import "qrcode_tools.h"


@interface ShareWithFriendsViewController ()

@end

@implementation ShareWithFriendsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self configUI];
    
    [self configQRCodeImageView];
}

- (void)configUI{
    self.title = DPLocalizedString(@"Setting_ShareWithFriends");
    self.view.backgroundColor = BACKCOLOR(238,238,238,1);
    self.shareTitle.text = DPLocalizedString(@"Share_Tips_Title");
    self.stepOneLabel.text = DPLocalizedString(@"Share_Tips_StepOne");
    self.stepTwoLabel.text = DPLocalizedString(@"Share_Tips_StepTwo_Title");
//    self.stepTwoContent.text = DPLocalizedString(@"Share_Tips_StepTwo_Content");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - QRCodeView
- (void)configQRCodeImageView{
    NSString * qrCodeStr = [self SetCGetQrCode];
    if (qrCodeStr != nil)
    {
        NSLog(@"qrCodeStr ==========================  %@",qrCodeStr);
        UIImage *qrcodeImage =
        [self createNonInterpolatedUIImageFormCIImage:[self createQRForString:qrCodeStr] withSize:160.0f];
        UIImage *customQrcode = [self imageBlackToTransparent:qrcodeImage withRed:1.0f andGreen:1.0f andBlue:1.0f];
        self.shareQRCode.image = customQrcode;
        
        
    }
}

-(NSString *)SetCGetQrCode
{
    NSString *string  = nil;
    if (_model != nil)
    {
        char *szData = NULL;
        int length = 0;
        
        goscam_qrcode_sharing_v1([_model.DeviceId UTF8String],[_model.StreamUser UTF8String],[_model.StreamPassword UTF8String],&szData,&length);
        if (length > 0)
        {
            string = [[NSString alloc] initWithCString:(const char*)szData
                                              encoding:NSASCIIStringEncoding];
        }
    }
    return string;
}


#pragma mark - InterpolatedUIImage
- (UIImage *)createNonInterpolatedUIImageFormCIImage:(CIImage *)image withSize:(CGFloat) size {
    CGRect extent = CGRectIntegral(image.extent);
    CGFloat scale = MIN(size/CGRectGetWidth(extent), size/CGRectGetHeight(extent));
    // create a bitmap image that we'll draw into a bitmap context at the desired size;
    size_t width = CGRectGetWidth(extent) * scale;
    size_t height = CGRectGetHeight(extent) * scale;
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef bitmapImage = [context createCGImage:image fromRect:extent];
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);
    // Create an image with the contents of our bitmap
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    // Cleanup
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);
    return [UIImage imageWithCGImage:scaledImage];
}

#pragma mark - QRCodeGenerator
- (CIImage *)createQRForString:(NSString *)qrString {
    // Need to convert the string to a UTF-8 encoded NSData object
    NSData *stringData = [qrString dataUsingEncoding:NSUTF8StringEncoding];
    // Create the filter
    CIFilter *qrFilter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    // Set the message content and error-correction level
    [qrFilter setValue:stringData forKey:@"inputMessage"];
    [qrFilter setValue:@"M" forKey:@"inputCorrectionLevel"];
    // Send the image back
    return qrFilter.outputImage;
}

#pragma mark - imageToTransparent
void ReleaseData (void *info, const void *data, size_t size){
    free((void*)data);
}
- (UIImage*)imageBlackToTransparent:(UIImage*)image withRed:(CGFloat)red andGreen:(CGFloat)green andBlue:(CGFloat)blue{
    const int imageWidth = image.size.width;
    const int imageHeight = image.size.height;
    size_t      bytesPerRow = imageWidth * 4;
    uint32_t* rgbImageBuf = (uint32_t*)malloc(bytesPerRow * imageHeight);
    // create context
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(rgbImageBuf, imageWidth, imageHeight, 8, bytesPerRow, colorSpace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipLast);
    CGContextDrawImage(context, CGRectMake(0, 0, imageWidth, imageHeight), image.CGImage);
    // traverse pixe
    int pixelNum = imageWidth * imageHeight;
    uint32_t* pCurPtr = rgbImageBuf;
    for (int i = 0; i < pixelNum; i++, pCurPtr++){
        if ((*pCurPtr & 0xFFFFFF00) < 0x99999900){
            // change color
            uint8_t* ptr = (uint8_t*)pCurPtr;
            ptr[3] = red; //0~255
            ptr[2] = green;
            ptr[1] = blue;
        }else{
            uint8_t* ptr = (uint8_t*)pCurPtr;
            ptr[0] = 0;
        }
    }
    // context to image
    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, rgbImageBuf, bytesPerRow * imageHeight, ReleaseData);
    CGImageRef imageRef = CGImageCreate(imageWidth, imageHeight, 8, 32, bytesPerRow, colorSpace,
                                        kCGImageAlphaLast | kCGBitmapByteOrder32Little, dataProvider,
                                        NULL, true, kCGRenderingIntentDefault);
    CGDataProviderRelease(dataProvider);
    UIImage* resultUIImage = [UIImage imageWithCGImage:imageRef];
    // release
    CGImageRelease(imageRef);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    return resultUIImage;
}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
