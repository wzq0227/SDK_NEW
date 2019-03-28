//
//  CheckNetTableViewCell.m
//  ULife3.5
//
//  Created by AnDong on 2018/8/29.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import "CheckNetTableViewCell.h"

typedef enum checkStatus {
    IsChecking,
    CheckWaiting,
    CheckSuccess,
    CheckFailed
} CheckStatus;

@implementation CheckNetTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setDic:(NSDictionary *)dic {
    _dic = dic;
    
    self.textLabel.text = dic[@"ip"];
    self.textLabel.font = [UIFont systemFontOfSize:14.0];
    [self updateImageView];
}

- (void)updateImageView {
    CheckStatus status = [_dic[@"status"] intValue];
    switch (status) {
        case IsChecking:
            self.image.hidden = YES;
            [self.activityView startAnimating];
            break;
            
        case CheckWaiting:
            self.image.hidden = YES;
            [self.activityView stopAnimating];
            self.activityView.hidden = YES;
            break;
            
        case CheckSuccess:
            self.image.image = [UIImage imageNamed:@"CheckNetPass"];
            self.image.hidden = NO;
            [self.activityView stopAnimating];
            self.activityView.hidden = YES;
            break;
            
        case CheckFailed:
            self.image.image = [UIImage imageNamed:@"CheckNetFailed"];
            self.image.hidden = NO;
            [self.activityView stopAnimating];
            self.activityView.hidden = YES;
            break;
    }
}
@end
