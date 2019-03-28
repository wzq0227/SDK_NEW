//
//  AlexaSkillViewController.m
//  ULife3.5
//
//  Created by 李子爽 on 2017/10/19.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "AlexaSkillViewController.h"

@interface AlexaSkillViewController ()

@end

@implementation AlexaSkillViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.title = @"Alexa";
    self.tittle1.text = DPLocalizedString(@"App support linking to Amazon Alexa");
    self.tittle2.text = DPLocalizedString(@"Clink “Jump to Alexa” to link to Alexa skills in Amazon app.");
    self.nextbtn.layer.cornerRadius=20;
}


- (IBAction)action:(id)sender {
    //https://skills-store.amazon.com/deeplink/dp/B076P9T2FQ?deviceType=app&share&refSuffix=ss_copy
    NSURL *url = [NSURL URLWithString:@"https://skills-store.amazon.com/deeplink/dp/B07D74ZW4W?deviceType=app&share&refSuffix=ss_copy"];
    if ([[UIApplication sharedApplication]canOpenURL:url]) {
        [[UIApplication sharedApplication]openURL:url];
    }
}




@end
