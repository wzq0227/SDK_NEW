//
//  DemoVideoTableViewCell.h
//  ULife3.5
//
//  Created by zhuochuncai on 07/08/2017.
//  Copyright © 2017 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DemoVideoTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *iconImage;

@property (weak, nonatomic) IBOutlet UILabel *videoTypeName;

@property (weak, nonatomic) IBOutlet UILabel *playedTimes;

@end
