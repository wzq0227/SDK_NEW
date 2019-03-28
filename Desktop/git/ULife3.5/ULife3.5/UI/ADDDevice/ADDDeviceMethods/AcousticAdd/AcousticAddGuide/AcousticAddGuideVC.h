//
//  AcousticAddGuideVC.h
//  ULife3.5
//
//  Created by Goscam on 2017/11/16.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, AcousticGuideGIFType) {
    AcousticGuideGIFType_StartAcousticAdd,
    AcousticGuideGIFType_StartPairingDevice,
};

@interface AcousticAddGuideVC : UIViewController

@property (weak, nonatomic) IBOutlet UIView *gifContainerView;

@property (weak, nonatomic) IBOutlet UILabel *longPressSignalBtnTipsLabel;

@property (weak, nonatomic) IBOutlet UIButton *haveHeardVoiceBtn;


@property (assign, nonatomic)  AcousticGuideGIFType gifType;
@end
