//  AddDeviceBindedViewController.m
//  ULife3.5
//
//  Create by daniel.hu on 2019/1/14.
//  Copyright © 2019年 GosCam. All rights reserved.

#import "AddDeviceBindedViewController.h"
#import "AddDeviceWiFiSettingViewController.h"

@interface AddDeviceBindedViewController ()
@property (weak, nonatomic) IBOutlet UILabel *topLabel;
@property (weak, nonatomic) IBOutlet UILabel *subTopLabel;
@property (weak, nonatomic) IBOutlet UIImageView *tipImageView;
@property (weak, nonatomic) IBOutlet UILabel *detailLabel;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;

@end

@implementation AddDeviceBindedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _topLabel.text = DPLocalizedString(@"AddDevice_DeviceBinded");
    _subTopLabel.text = DPLocalizedString(@"AddDevice_DeviceBindedTip");
    
    _detailLabel.attributedText = [self detailAttrText];
    _nextButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    [_nextButton setTitle:DPLocalizedString(@"ADDDevice_WiFiStationNextStep") forState:UIControlStateNormal];
    _nextButton.layer.cornerRadius = _nextButton.frame.size.height/2.0;
    _nextButton.layer.masksToBounds = YES;
    
    [self configBackBtn];
}


- (void)configBackBtn{
    UIImage *image = [UIImage imageNamed:@"addev_back"];
    EnlargeClickButton *button = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 0, 70, 40);
    button.imageEdgeInsets = UIEdgeInsetsMake(10, 0, 10, 50);
    [button setImage:image forState:UIControlStateNormal];
    [button addTarget:self
               action:@selector(nextButtonDidClick:)
     forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    leftBarButtonItem.style = UIBarButtonItemStylePlain;
    self.navigationItem.leftBarButtonItem = leftBarButtonItem;
}

- (NSAttributedString *)detailAttrText {
    NSString *str = DPLocalizedString(@"AddDevice_DeviceBindedDetailTip");
    NSString *rep1 = @"\"!\"";
    NSString *rep2 = @"\"*\"";
    
    NSTextAttachment *att1 = [[NSTextAttachment alloc] init];
    att1.image = [UIImage imageNamed:@"AcousticAdd_icon_wifi"];
    att1.bounds = CGRectMake(0, 0, 12, 12);
    
    NSTextAttachment *att2 = [[NSTextAttachment alloc] init];
    att2.image = [UIImage imageNamed:@"AcousticAdd_icon_music"];
    att2.bounds = CGRectMake(0, 0, 12, 12);
    
    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithString:str attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14], NSForegroundColorAttributeName:GOS_COLOR_RGB(0x333333)}];
    [result replaceCharactersInRange:[[result string] rangeOfString:rep1] withAttributedString:[NSAttributedString attributedStringWithAttachment:att1]];
    [result replaceCharactersInRange:[[result string] rangeOfString:rep2] withAttributedString:[NSAttributedString attributedStringWithAttachment:att2]];
    
    return [result copy];
}

- (IBAction)nextButtonDidClick:(id)sender {
    UIViewController *target = nil;
    for (UIViewController * controller in self.navigationController.viewControllers) {
        if ([controller isKindOfClass:[AddDeviceWiFiSettingViewController class]]) {
            target = controller;
            break;
        }
    }
    if (target) {
        [self.navigationController popToViewController:target animated:NO];
    }
}


@end
