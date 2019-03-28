//
//  PackageTotalPriceCell.h
//  ULife3.5
//
//  Created by Goscam on 2017/9/15.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PackageTotalPriceCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *priceLabel;

@property (weak, nonatomic) IBOutlet UILabel *countLabel;

@property (weak, nonatomic) IBOutlet UILabel *totalPriceLabel;

@property (weak, nonatomic) IBOutlet UIView *separatorLine;

@end
