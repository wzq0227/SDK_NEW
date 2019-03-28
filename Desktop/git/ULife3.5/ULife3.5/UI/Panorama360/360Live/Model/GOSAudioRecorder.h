//
//  GOSAudioRecorder.h
//  ULife3.5
//
//  Created by Goscam on 2017/8/15.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 操作结果回调

 @param result 0 成功 -1失败
 */
typedef void(^OperationResult)(int result, NSString *filePath);

@interface GOSAudioRecorder : NSObject


/**
 开启对讲并开始录音
 */
- (void)gos_startAudioRecorderResultCallback:(OperationResult)result;


/**
 停止录音并发送对讲
 */
-(void)gos_stopAudioRecorderResultCallback:(OperationResult)result;


@end
