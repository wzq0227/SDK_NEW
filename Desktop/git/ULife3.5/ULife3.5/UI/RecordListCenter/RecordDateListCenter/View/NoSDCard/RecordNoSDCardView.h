//
//  RecordNoSDCardView.h
//  ULife3.5
//
//  Created by zhuochuncai on 13/6/17.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RecordNoSDCardView : UIView

@property (weak, nonatomic) IBOutlet UILabel *noSDCardTitle;

@property (weak, nonatomic) IBOutlet UILabel *sdCardAutoDetect;

@property (weak, nonatomic) IBOutlet UILabel *sdCardSupportedType;

@property (weak, nonatomic) IBOutlet UILabel *sdCardUnrecognized;


@property (weak, nonatomic) IBOutlet UILabel *sdCardFAT32;


@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *noSDCardIconArray;

@property (weak, nonatomic) IBOutlet UIButton *okBtn;


@end
