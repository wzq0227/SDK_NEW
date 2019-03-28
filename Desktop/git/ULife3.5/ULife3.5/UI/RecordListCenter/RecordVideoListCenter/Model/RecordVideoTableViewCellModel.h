//
//  RecordVideoTableViewCellModel.h
//  goscamapp
//
//  Created by shenyuanluo on 2017/4/28.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RecordVideoTableViewCellModel : NSObject

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
 *  视频文件是否下载
 */
@property (nonatomic, assign) BOOL isDownload;

/**
 *  视频是否被选中
 */
@property (nonatomic, assign) BOOL isSelect;

@end
