//
//  NvrPlayCtrlView.h
//  ULife3.5
//
//  Created by shenyuanluo on 2017/8/15.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>

/** 录像按钮样式*/
typedef NS_ENUM(NSInteger, RecordBtnStyle) {
    RecordBtnDisable                = 0,            // 不可用
    RecordBtnNormal                 = 1,            // 常态
    RecordBtnHighLight              = 2,            // 高亮
};

@protocol NvrPlayCtrlViewDelegate <NSObject>


/**
 ‘录像’按钮事件代理
 */
- (void)recordButtonAction;


/**
 ‘拍照’按钮事件代理
 */
- (void)snapshotButtonAction;


/**
 ‘相册’按钮事件代理
 */
- (void)photoAlbumButtonAction;

@end

@interface NvrPlayCtrlView : UIView

@property (nonatomic, weak) id<NvrPlayCtrlViewDelegate>delegate;

/**
 设置‘录像’按钮样式

 @param btnStyle 按钮样式，参见‘RecordBtnStyle’
 */
- (void)configRecordBtnStyle:(RecordBtnStyle)btnStyle;

@end
