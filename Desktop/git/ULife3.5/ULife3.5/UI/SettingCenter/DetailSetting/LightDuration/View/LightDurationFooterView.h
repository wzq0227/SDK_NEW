//
//  LightDurationFooterView.h
//  ULife3.5
//
//  Created by zhuochuncai on 5/6/17.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlackLineCustomView.h"

typedef void(^SelectDaysBlock)(int selectedDays);

@interface LightDurationFooterView : UITableViewHeaderFooterView
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property(nonatomic,assign)int selectedWeekdays;

@property (weak, nonatomic) IBOutlet BlackLineCustomView *blackLineView;

- (void)selectWeekdaysCallback:(SelectDaysBlock)block;

@end
