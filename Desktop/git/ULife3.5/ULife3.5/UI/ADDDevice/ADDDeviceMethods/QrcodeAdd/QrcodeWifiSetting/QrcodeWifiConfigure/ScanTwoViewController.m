//
//  ScanTwoViewController.m
//  UI——update
//
//  Created by goscam_sz on 16/6/30.
//  Copyright © 2016年 goscam_sz. All rights reserved.
//

#import "ScanTwoViewController.h"
#import "CustomWindow.h"
#import "ScanThreeViewController.h"
#import "qrcode_tools.h"
#import "TsButton.h"
#import "SaveDataModel.h"

@interface ScanTwoViewController ()
{
    CustomWindow *customWindow;
    BOOL wringAction;
    int changge;
}

@property (weak, nonatomic) IBOutlet UIImageView *QRCodeView;
@property (strong, nonatomic) IBOutlet UILabel *textLabel;
@property (weak, nonatomic) IBOutlet TsButton *IHeardBtn;
@property (weak, nonatomic) IBOutlet UIButton *NoVoiceBtn;
@end

@implementation ScanTwoViewController

- (void)viewWillAppear:(BOOL)animated
{
    self.navigationController.navigationBar.hidden=NO;
    
    BOOL ret = [SaveDataModel isQrscanSate];
    if (!ret) {
        
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"CustomView" owner:self options:nil];
        UIView *tmpContentView = [nib objectAtIndex:0];
        tmpContentView.layer.cornerRadius=12;
        tmpContentView.frame= CGRectMake(0, 0, 280, 288);
        if (customWindow == NULL) {
            customWindow = [[CustomWindow alloc]initWithView:tmpContentView];
            
            UILabel  *tiplabel     = (UILabel  *)[tmpContentView viewWithTag:203];
            UILabel  *label        = (UILabel  *)[tmpContentView viewWithTag:202];
            UIButton *tmpButton    = (UIButton *)[tmpContentView viewWithTag:200];
            UIButton *ChangeButton = (UIButton *)[tmpContentView viewWithTag:201];
            
            label.text    =DPLocalizedString(@"Qrcode_customView_label1");
            tiplabel.text =DPLocalizedString(@"Qrcode_customView_btn");
            
            [tmpButton setTitle:DPLocalizedString(@"Qrcode_Title_Confirm") forState:0];
            [tmpButton    addTarget:self
                             action:@selector(Next:)
                   forControlEvents:UIControlEventTouchUpInside];
            
            [ChangeButton addTarget:self
                             action:@selector(WringAction:)
                   forControlEvents:UIControlEventTouchUpInside];
        }
        [customWindow show];
    }
}

-(void)WringAction:(id)sender{
    UIButton *Button = (UIButton *)[sender viewWithTag:201];
    wringAction=!wringAction;
    if(wringAction){
        [Button setImage:[UIImage imageNamed:@"addev_action_light"]
                forState:UIControlStateNormal];
        changge=1;
    }
    else{
        [Button setImage:[UIImage imageNamed:@"addev_action_normal"]
                forState:UIControlStateNormal];
        changge=0;
    }
}

- (void)Next:(id)sender {
    
    NSLog (@"+++ okAction executing. +++");
    if (changge==1) {
        [SaveDataModel SaveQRscanState:YES];
    }
    else{
        [SaveDataModel SaveQRscanState:NO];
    }
    [customWindow close];
    customWindow.hidden = true;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.title =DPLocalizedString(@"Qrcode");
    [self createQRCodeImage];
    self.textLabel.text=DPLocalizedString(@"Qrcode_showlabel");
    
    [_IHeardBtn setTitle:DPLocalizedString(@"Qrcode_soundBtn")
                forState:UIControlStateNormal];
    [_NoVoiceBtn setTitle:DPLocalizedString(@"Qrcode_unsoundBtn")
                 forState:UIControlStateNormal];
    [self addBackBtn];
}

-(void)addBackBtn
{
    EnlargeClickButton *backButton = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
    backButton.frame = CGRectMake(0, 0, 70, 40);
    backButton.imageEdgeInsets = UIEdgeInsetsMake(10, 0, 10, 50);
    [backButton setImage:[UIImage imageNamed:@"addev_back"] forState:UIControlStateNormal];
    
    [backButton addTarget:self action:@selector(backToPreView) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    temporaryBarButtonItem.style = UIBarButtonItemStylePlain;
    self.navigationItem.leftBarButtonItem = temporaryBarButtonItem;
}

-(void)backToPreView{
    [self.navigationController popViewControllerAnimated:YES];
}


- (IBAction)NotSoundBtn:(id)sender {
    //    self.title=@"扫描二维码";
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"CustomView" owner:self options:nil];
    UIView *tmpContentView = [nib objectAtIndex:1];
    tmpContentView.layer.cornerRadius=12;
    
    UILabel    * tipsTitle    = (UILabel    *)[tmpContentView   viewWithTag:3000];
    UITextView * textview     = (UITextView *)[tmpContentView   viewWithTag:3001];
    UIButton   * ChangeButton = (UIButton   *)[tmpContentView   viewWithTag:3002];
    
    [ChangeButton setTitle:DPLocalizedString(@"Title_Confirm") forState:0];
    [ChangeButton addTarget:self
                     action:@selector(okAction:)
           forControlEvents:UIControlEventTouchUpInside];
    
    tipsTitle.text =DPLocalizedString(@"Qrcode_tipsTitle");
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 10;// 字体的行间距
    
    NSDictionary *attributes = @{
                                 NSFontAttributeName:[UIFont systemFontOfSize:14],
                                 NSParagraphStyleAttributeName:paragraphStyle
                                 };
    
    textview.attributedText = [[NSAttributedString alloc]
                               initWithString:DPLocalizedString(@"Qrcode_textView")
                                   attributes:attributes];
    
    [ChangeButton setTitle:DPLocalizedString(@"Qrcode_Title_Confirm")
                  forState:UIControlStateNormal];
    
    customWindow = [[CustomWindow alloc]initWithView:tmpContentView];
    [customWindow show];
}

-(void)viewDidDisappear:(BOOL)animated
{
    if (customWindow != nil) {
        [customWindow  close];
        customWindow = nil;
    }
}

- (IBAction)OkSoundBtn:(id)sender {
    ScanThreeViewController *scan =[ScanThreeViewController alloc];
    scan.scanType = self.scanType;
    scan.UID = self.deviceID;
    scan.devName=self.devName;
    scan.deviceType = self.deviceType;
    [self.navigationController
           pushViewController:scan
                     animated:NO];
}

- (void)okAction:(id)sender {
    [customWindow close];
    customWindow.hidden = true;
}

-(void)createQRCodeImage
{
    NSString * strviwe = [self SetCGetQrCode];
    if (strviwe != nil)
    {
        NSLog(@"strviwe = %@",strviwe);
        UIImage *qrcode =
        [self createNonInterpolatedUIImageFormCIImage:[self createQRForString:strviwe] withSize:400.0f];
        UIImage *customQrcode = [self imageBlackToTransparent:qrcode withRed:1.0f andGreen:1.0f andBlue:1.0f];
        self.QRCodeView.image = customQrcode;
    }
    else
    {
        NSLog(@"strviwe = nil");
    }
}

-(NSString *)SetCGetQrCode
{
    NSString *string  = nil;
    
    if (_deviceID != nil)
    {
        char *szData = NULL;
        int length = 0;
        CGetQrCode *cmdCtrlReq = goscam_qrcode_create(QRC_ACTION_SMART_CONFIG);
        if (cmdCtrlReq != NULL) {
            if ([_deviceID length] < QRC_DEF_STR_LEN) {
                strcpy(cmdCtrlReq->szDevID, [_deviceID UTF8String]);
            }
            
            NSData *pswData = [self.wifiPWD dataUsingEncoding:NSUTF8StringEncoding];
            if ([pswData length] < QRC_DEF_STR_LEN) {
                strcpy(cmdCtrlReq->szWifiPwd, [self.wifiPWD UTF8String]);
            }
            
            
            NSData *wifiData = [self.wifiStr dataUsingEncoding:NSUTF8StringEncoding];
            if (wifiData.length < QRC_DEF_STR_LEN) {
                strcpy(cmdCtrlReq->szWifiSSID, [self.wifiStr UTF8String]);
            }
            
            goscam_qrcode_getqrtext(cmdCtrlReq,&szData,&length);
            if (length > 0) {
                string = [[NSString alloc] initWithCString:(const char*)szData
                                                  encoding:NSASCIIStringEncoding];
            }
            goscam_qrcode_destroy(cmdCtrlReq);
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
    [qrFilter setValue:@"L" forKey:@"inputCorrectionLevel"];
    // Send the image back
    return qrFilter.outputImage;
}

#pragma mark - imageToTransparent
void ProviderReleaseData (void *info, const void *data, size_t size){
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
    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, rgbImageBuf, bytesPerRow * imageHeight, ProviderReleaseData);
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;;
}



@end
