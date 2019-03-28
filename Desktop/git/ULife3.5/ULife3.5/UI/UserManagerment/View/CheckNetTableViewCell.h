//
//  CheckNetTableViewCell.h
//  ULife3.5
//
//  Created by AnDong on 2018/8/29.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CheckNetTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *image;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityView;

@property (nonatomic) NSDictionary *dic;
@end
