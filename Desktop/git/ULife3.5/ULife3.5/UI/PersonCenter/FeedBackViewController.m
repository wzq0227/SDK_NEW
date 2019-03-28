//
//  FeedBackViewController.m
//  ULife3.5
//
//  Created by 广东省深圳市 on 2017/7/20.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "FeedBackViewController.h"
#import <Masonry.h>
#import <MessageUI/MFMailComposeViewController.h>

@interface FeedBackViewController ()<UITextViewDelegate,MFMailComposeViewControllerDelegate>

@end

@implementation FeedBackViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    [self addbackbtn];
    [self setUI];
}

- (void)setUI
{
    self.view.backgroundColor= [UIColor whiteColor];
    self.title = DPLocalizedString(@"Personal_feedback");
    UITextView * view = [[UITextView alloc]init];
    view.delegate=self;
    view.editable=NO;
    view.scrollEnabled=NO;
    
    
    view.backgroundColor=[UIColor clearColor];
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:@"support@goscam.com"];
    
    [attributedString addAttribute:NSLinkAttributeName
                             value:@"jianhang://"
                             range:[[attributedString string] rangeOfString:@"support@goscam.com"]];
    [attributedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:14] range:NSMakeRange(0, attributedString.length)];
    view.attributedText = attributedString;
    view.linkTextAttributes = @{NSForegroundColorAttributeName: BACKCOLOR(49,55,123,1),
                                NSUnderlineColorAttributeName: [UIColor lightGrayColor],
                                NSUnderlineStyleAttributeName: @(NSUnderlinePatternSolid)};
    [self.view addSubview:view];
    
    view.textAlignment = NSTextAlignmentCenter;
    [view mas_updateConstraints:^(MASConstraintMaker *make) {
        __weak typeof(self)weakSelf = self;
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            return ;
        }
        make.top.equalTo(strongSelf.view.mas_top).offset(60);
        //        make.centerX.equalTo(strongSelf.view);
        make.centerX.equalTo(strongSelf.view);
        make.height.mas_equalTo(40);
        make.width.mas_equalTo(200);
    }];
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
    if ([[URL scheme] isEqualToString:@"jianhang"]) {
        //        NSLog(@"建行支付---------------");
        //        NSURL *url = [NSURL URLWithString:@"MESSAGE://"];
        //                if ([[UIApplication sharedApplication]canOpenURL:url]) {
        //                    [[UIApplication sharedApplication]openURL:url];
        //
        //                }
        [self sendemail];
        
        
        
        return NO;
    }
    return YES;
}


-(void)sendemail{
    Class mailClass = (NSClassFromString(@"MFMailComposeViewController"));
    if (!mailClass) {
        
        [self launchMailAppOnDevice];
        
    }else{
        
        if (![mailClass canSendMail]) {
            
            [self launchMailAppOnDevice];
        }else {
            [self displayMailPicker];
        }
    }
}



-(void)launchMailAppOnDevice

{
    
    UIAlertView  *isEmailalert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"MFMail_00005", nil) message:NSLocalizedString(@"MFMail_00006", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"MFMail_CancelBtnTilte", nil) otherButtonTitles:NSLocalizedString(@"MFMail_OtherBtnTilte", nil),nil];
    
    [isEmailalert show];
    
}
//调出邮件发送窗口
- (void)displayMailPicker
{
    MFMailComposeViewController *mailPicker = [[MFMailComposeViewController alloc] init];
    mailPicker.mailComposeDelegate = self;
    
    
    [mailPicker setMessageBody:@"" isHTML:YES];
    
    [mailPicker setToRecipients:[NSArray arrayWithObject:@"support@goscam.com"]];
    
    mailPicker.navigationBar.tintColor = [UIColor whiteColor];
    
    [self presentViewController:mailPicker animated:YES completion:nil];
    //[mailPicker release];
}

#pragma mark - 实现 MFMailComposeViewControllerDelegate
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    //关闭邮件发送窗口
    [self back];
    
    NSString *msg;
    switch (result) {
        case MFMailComposeResultCancelled:
            msg = NSLocalizedString(@"MFMailComposeResultCancelled", nil);
            break;
        case MFMailComposeResultSaved:
            msg = NSLocalizedString(@"MFMailComposeResultSaved", nil);
            break;
        case MFMailComposeResultSent:
            msg = NSLocalizedString(@"MFMailComposeResultSent", nil);
            break;
        case MFMailComposeResultFailed:
            msg = NSLocalizedString(@"MFMailComposeResultFailed", nil);
            break;
        default:
            msg = @"";
            break;
    }
    NSLog(@"%@",msg);
}


-(void)back{
    [self dismissViewControllerAnimated:YES completion:nil];
}



- (void)addbackbtn
{
    UIImage* img=[UIImage imageNamed:@"addev_back"];
    EnlargeClickButton *btn = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(0, 0, 70, 40);
    btn.imageEdgeInsets = UIEdgeInsetsMake(10, 0, 10, 50);
    [btn setImage:img forState:UIControlStateNormal];
    [btn addTarget: self action: @selector(presentLeftMenuViewController:) forControlEvents: UIControlEventTouchUpInside];
    UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:btn];
    temporaryBarButtonItem.style = UIBarButtonItemStylePlain;
    self.navigationItem.leftBarButtonItem=temporaryBarButtonItem;
}


@end
