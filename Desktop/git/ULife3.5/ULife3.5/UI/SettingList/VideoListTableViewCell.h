//
//  VideoListCell.h
//  goscamapp
//
//  Created by goscam_sz on 17/4/20.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "Header.h"
#import "VideoModel.h"
@interface VideoListTableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UIImageView *headerImageView;
@property (strong, nonatomic) IBOutlet UILabel *FirstLabel;
@property (strong, nonatomic) IBOutlet UILabel *SecondLabel;


-(void)freshen:(VideoModel *)md;


@end
