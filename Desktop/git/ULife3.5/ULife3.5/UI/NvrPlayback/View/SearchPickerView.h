//
//  SearchPickerView.h
//  ULife3.5
//
//  Created by shenyuanluo on 2017/8/16.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef NS_ENUM(NSInteger, DatePickerStyle) {
    DatePickerDate                  = 0,        // 日期 Date Picker
    DatePickerStartTime             = 1,        // 起始时间 Date Picker
    DatePickerEndTime               = 2,        // 结束时间 Date Picker
};

typedef NS_ENUM(NSInteger, PickerViewStyle) {
    SearchPickerViewType            = 0,        // 类型 Picker View
    SearchPickerViewChannel         = 1,        // 频道 Picker View
};


@protocol SearchPickerViewDelegate <NSObject>

/**
 日期选择

 @param dateStr 日期（yyyy-mm-dd)
 */
- (void)selectedDate:(NSString *)dateStr;

/**
 起始时间选择

 @param startTimeStr 起始时间（HH-mm)
 */
- (void)selectedStartTime:(NSString *)startTimeStr;

/**
 结束时间选择
 
 @param endTimeStr 结束时间（HH-mm)
 */
- (void)selectedEndTime:(NSString *)endTimeStr;

/**
 类型选择

 @param typeStr 类型
 */
- (void)selectedType:(NSString *)typeStr;

/**
 频道选择

 @param channleStr 频道
 */
- (void)selectedChannel:(NSString *)channleStr;



@end

@interface SearchPickerView : UIView

@property (nonatomic, weak) id<SearchPickerViewDelegate>delegate;


/**
 隐藏/显示 日期 Picker
 
 @param isHidden 是否隐藏，YES：隐藏，NO：显示
 */
- (void)configDatePicker:(DatePickerStyle)datePickerStyle
                isHidden:(BOOL)isHidden;


/**
 隐藏/显示 Picker View

 @param pickerViewStyle PickerView 对象枚举，参见‘PickerViewStyle’
 @param isHidden 是否隐藏，YES：隐藏，NO：显示
 */
- (void)configPickerView:(PickerViewStyle)pickerViewStyle
                isHidden:(BOOL)isHidden;

@end
