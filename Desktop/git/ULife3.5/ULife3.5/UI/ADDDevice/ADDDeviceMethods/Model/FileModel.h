//
//  FileModel.h
//  ULifePro
//
//  Created by zhuochuncai on 12/4/17.
//  Copyright © 2017年 Gospell. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum FileType
{
    File_mp4 = 0,
    File_img,
}
FileType;

@interface FileModel : NSObject
@property (nonatomic,copy)NSString *fileName;
@property(nonatomic,copy)NSString *fileTime;
@property(nonatomic,copy)NSString *fileSizeName;
@property(nonatomic,copy)NSString *filePath;
@property(nonatomic,copy)NSString *fileSize;
@property(nonatomic,assign)FileType fileType;
@property(nonatomic,assign)BOOL fileDownLoadState;
@end
