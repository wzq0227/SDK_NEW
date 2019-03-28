//
//  MoniterAreaTableViewCell.h
//  ULife3.5
//
//  Created by zhuochuncai on 4/6/17.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RedLineCustomView.h"

typedef void(^SelectAreaBlock)(int selectPosition);

@interface MoniterAreaTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (weak, nonatomic) IBOutlet UIImageView *bgImageView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *collectionWidthToSuperConstraint;

@property(nonatomic,assign)unsigned int selectedArea;

@property (weak, nonatomic) IBOutlet RedLineCustomView *redBlueLineView;


- (void)selectMoniterAreaCallback:(SelectAreaBlock)block;
@end
