//
//  RecordImgTableViewCellModel.h
//  goscamapp
//
//  Created by shenyuanluo on 2017/4/28.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RecordImgTableViewCellModel : NSObject

/**
 *  图片日期
 */
@property (nonatomic, copy) NSString *recordImgDateStr;

/**
 *  图片时间
 */
@property (nonatomic, copy) NSString *recordImgTimeStr;

/**
 *  图片文件名称
 */
@property (nonatomic, copy) NSString *recordImgFileNameStr;

/**
 *  图片文件目录
 */
@property (nonatomic, copy) NSString *recordFilePath;


/**
 *  图片文件大小
 */
@property (nonatomic, copy) NSString *recordImgFileSizeStr;

/**
 *  图片文件是否下载
 */
@property (nonatomic, assign) BOOL isDownload;

/**
 *  视频是否被选中
 */
@property (nonatomic, assign) BOOL isSelect;

@end
