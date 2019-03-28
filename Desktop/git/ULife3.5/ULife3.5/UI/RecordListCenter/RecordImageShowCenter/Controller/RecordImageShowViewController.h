//
//  RecordImageShowViewController.h
//  goscamapp
//
//  Created by shenyuanluo on 2017/4/28.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RecordImageShowViewController : UIViewController

/**
 *  录像‘图片’文件名
 */
@property (nonatomic, copy) NSString *recordImgFileName;

/**
 *  录像‘图片’文件路径
 */
@property (nonatomic, copy) NSString *recordImgFilePath;

@end
