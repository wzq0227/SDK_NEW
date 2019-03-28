//
//  RecordImgTableViewCell.h
//  goscamapp
//
//  Created by shenyuanluo on 2017/4/28.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RecordImgTableViewCellModel.h"
#import "LocalVideoModel.h"
#import "MediaManager.h"

@class RecordImgTableViewCell;

typedef void(^imgSelectBlock)(BOOL isSelect,RecordImgTableViewCell *cell);

typedef void(^stateBlock)(BOOL isSelect);

@interface RecordImgTableViewCell : UITableViewCell

/**
 *  RecordImgTableView cell 数据对象
 */
@property (strong, nonatomic) RecordImgTableViewCellModel *recordImgTableViewCellData;

/**
 *  本地数据cell 数据对象
 */
@property (strong, nonatomic) LocalVideoModel *localVideoModel;

/** 本地媒体文件（拍照） cell 数据对象 */
@property (nonatomic, strong) MediaFileModel *mediaFileCellData;


/**
 *  是否为编辑模式
 */
@property (assign, nonatomic)BOOL isEditStyle;

/**
 选中事件回调block
 */
@property (nonatomic,copy)imgSelectBlock selectBlock;

@property (nonatomic,copy)stateBlock  myStateBlock;


- (void)setStatusImgViewHidden:(BOOL)isHidden;


/**
 ☑️按钮是否响应点击事件

 @param enabled YES 表示响应 NO 不响应
 */
- (void)setSelectBtnEnabled:(BOOL)enabled;

@end
