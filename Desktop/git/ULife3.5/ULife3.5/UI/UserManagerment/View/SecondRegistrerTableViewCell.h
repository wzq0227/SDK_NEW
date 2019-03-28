//
//  SecondRegistrerTableViewCell.h
//  goscamapp
//
//  Created by goscam_sz on 17/5/9.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SecondRegisterTableViewCellDelegate <NSObject>


@required

- (void)CellHight:(CGFloat )str;





@end


@interface SecondRegistrerTableViewCell : UITableViewCell

@property (nonatomic,weak) id<SecondRegisterTableViewCellDelegate> delegate;

@property (strong, nonatomic) IBOutlet UILabel *TextLabel;


- (void)refresh:(NSString *)str;

@end
