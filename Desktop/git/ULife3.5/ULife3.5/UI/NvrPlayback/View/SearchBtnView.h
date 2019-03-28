//
//  SearchBtnView.h
//  ULife3.5
//
//  Created by shenyuanluo on 2017/8/16.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EnlargeClickButton.h"

@protocol SearchBtnViewDelegate <NSObject>

/**
 ‘搜索日期’按钮事件 代理回调
 */
- (void)searchDateButtonAction;

/**
 ‘搜索起始时间’按钮事件 代理回调
 */
- (void)searchStartTimeButtonAction;


/**
 ‘搜索结束时间’按钮事件 代理回调
 */
- (void)searchEndTimeButtonAction;


/**
 ‘搜索类型’按钮事件 代理回调
 */
- (void)searchTypButtoneAction;


/**
 ‘搜索频道’按钮事件 代理回调
 */
- (void)searchChannelButtonAction;


/**
 ‘搜索’按钮事件 代理回调
 */
- (void)searchButtonAction;

@end

@interface SearchBtnView : UIView

@property (nonatomic, weak) id<SearchBtnViewDelegate>delegate;

/** 搜索日期 Button */
@property (nonatomic, strong) EnlargeClickButton *searchDateBtn;

/** 搜索起始时间 Button */
@property (nonatomic, strong) EnlargeClickButton *searchStartTimeBtn;

/** 搜索结束 Button */
@property (nonatomic, strong) EnlargeClickButton *searchEndTimeBtn;

/** 搜索类型 Button */
@property (nonatomic, strong) EnlargeClickButton *searchTypeBtn;

/** 搜索频道 Button */
@property (nonatomic, strong) EnlargeClickButton *searchChannelBtn;

/** 搜索 Button */
@property (nonatomic, strong) EnlargeClickButton *searchBtn;


/**
 更新按钮 title

 @param titleStr 标题
 */
- (void)updateButton:(EnlargeClickButton *)button
           withTitle:(NSString *)titleStr;

@end
