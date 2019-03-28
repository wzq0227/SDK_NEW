//
//  LocalVideoModel.h
//  ULife3.5
//
//  Created by 广东省深圳市 on 2017/6/21.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LocalVideoModel : NSObject

/**
 *  视频日期
 */
@property (nonatomic, copy) NSString *recordVideoDateStr;

/**
 *  视频时间
 */
@property (nonatomic, copy) NSString *recordVideoTimeStr;

/**
 *  视频文件名称
 */
@property (nonatomic, copy) NSString *recordVideoFileNameStr;

/**
 *  视频文件大小
 */
@property (nonatomic, copy) NSString *recordVideoFileSizeStr;

/**
 *  视频文件目录
 */
@property (nonatomic, copy) NSString *recordFilePath;

/**
 *  图片/视频
 */
@property (nonatomic, assign) BOOL isVideo;


/**
 *  视频是否被选中
 */
@property (nonatomic, assign) BOOL isSelect;


@end
