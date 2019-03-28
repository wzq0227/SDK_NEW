//
//  CloudPlayViewController.m
//  TestAli
//
//  Created by AnDong on 2017/10/9.
//  Copyright © 2017年 AnDong. All rights reserved.
//

#import "CloudPlayViewController.h"
#import "OSSClient.h"
#import "OSSModel.h"
#import "AFNetworking.h"
#import "AHRuler.h"
#import "OSSUtil.h"
#import "OSSTask.h"
#import "CloudAlarmModel.h"
#import "CloudVideoModel.h"
#import "YYModel.h"
#import "Masonry.h"
#import "UIColor+YYAdd.h"
#import "CloudShortCutViewController.h"
#import "GDVideoPlayer.h"
#import "ACVideoDecoder.h"
#import "GDPlayerView.h"
#import "PCMPlayer.h"
#import "SaveDataModel.h"
#import "CloudPlayModel.h"
#import "MediaManager.h"



//播放通知Key
static NSString *const PlayStatusNotification = @"PlayStatusNotification";
static NSString *const ConvertMP4Notification = @"ConvertMP4Notification";

#define HOMECOLOR [UIColor colorWithRed:53/255.0 green:153/255.0 blue:54/255.0 alpha:1]
#define degreesToRadian(x) (M_PI * (x) / 180.0)
#define playViewRatio (iPhone4 ? (3/4.0f):(9.0/16.0f))
#define trueSreenWidth  (MIN(SCREEN_WIDTH, SCREEN_HEIGHT))
#define trueScreenHeight (MAX(SCREEN_WIDTH, SCREEN_HEIGHT))

@interface CloudPlayViewController ()<AHRrettyRulerDelegate,UIPickerViewDataSource,UIPickerViewDelegate>{
   // UILabel *showLabel;
}

@property (nonatomic,strong)OSSClient *client;

//token返回的字典
@property (nonatomic,strong)NSDictionary *tokenDict;
//
////播放器View
//@property (nonatomic,strong)UIView *playView;

//当前选中日期
@property (nonatomic,strong)NSDate *currentSelectDate;

//当前时间日期
@property (nonatomic,strong)NSDate *currentTimeDate;

//日期选择view
@property (nonatomic,strong)UIPickerView *pickView;

//pickView date Array
@property (nonatomic,strong)NSMutableArray *dateArray;

//选择日期按钮
@property (nonatomic,strong)UIButton *dateButton;

//录制视频数组
@property (nonatomic,strong)NSMutableArray *cloudVideoArray;

//录制视频url数组
@property (nonatomic,strong)NSMutableArray *cloudPlayUrlArray;

//报警视频数组
@property (nonatomic,strong)NSMutableArray *cloudAlarmArray;

//刻度尺
@property (nonatomic,strong)AHRuler *ruler;

////播放器View
//@property (nonatomic,strong)ADPlayer *player;

/** 底部 View */
@property (strong, nonatomic)  UIView *bottomView;

/** 声音开关 Button */
@property (strong, nonatomic)  UIButton *soundBtn;

/** 剪切 Button */
@property (strong, nonatomic) UIButton *shortCutBtn;

/** 拍照 Button */
@property (strong, nonatomic) UIButton *snapshotBtn;

/** 声音开关 Label */
@property (nonatomic,strong)UILabel *soundLabel;

/** 剪切 Label */
@property (nonatomic,strong)UILabel *shortCutLabel;

/** 拍照 Label */
@property (nonatomic,strong)UILabel *snapshotLabel;

//顶部View
@property (nonatomic,strong)UIView *topView;

@property (nonatomic,strong)UIView *pickCoverView;

@property(nonatomic,strong)NSString *h264FilePath;
/**
 视频显示画面宽
 */
@property(nonatomic,assign)CGFloat displayWidth;

/**
 视频显示画面高
 */
@property(nonatomic,assign)CGFloat displayHeight;

/**
 视频实际宽
 */
@property(nonatomic,assign)CGFloat videoWidth;

/**
 视频实际高
 */
@property(nonatomic,assign)CGFloat videoHeight;

/**
 视频解码器
 */
@property(nonatomic,strong)ACCloudVideoDecoder *videoDecoder;

/**
 预览图解码器
 */
@property(nonatomic,strong)ACSeekVideoDecoder *previewDecoder;

//播放器View
@property(nonatomic,strong)GDPlayerView *playerView;

//音频播放器
@property (nonatomic,strong)PCMPlayer *pcmPlayer;

@property (nonatomic,strong)KxVideoFrameYUV *yuvFrame;

//是否有声音
@property (nonatomic,assign)BOOL isHasSound;

//当前播放的模型在数组中的索引，用于自动播放和下载下一个 --只会缓存下载一个
@property (nonatomic,assign)NSInteger currentPlayIndex;

//当前播放的模型
@property (nonatomic,strong)CloudPlayModel *currentPlayModel;

//预览图View
@property (nonatomic,strong)UIButton *previewView;

@property (nonatomic,strong)UIImageView *playImageView;

@property (nonatomic,strong)UIImageView *iconImgaeView;

@property (nonatomic,strong)UILabel *timeLabel;

//是否正在连续播放
@property (nonatomic,assign)BOOL isPlaying;

//拖动时候预览时间点
@property (nonatomic,assign)NSInteger currentPreviewSeekTimeIndex;

//拖动时候缓存预览时间点
@property (nonatomic,assign)NSInteger currentPreviewCacheSeekTimeIndex;

//拖动时候播放的时间点
@property (nonatomic,assign)NSInteger currentPlaySeekTimeIndex;

//实际当前播放的model
@property (nonatomic,strong)CloudPlayModel *currentActurePlayModel;

//currentSeekModel
@property (nonatomic,strong)CloudPlayModel *currentSeekModel;

@property (nonatomic,strong)UIActivityIndicatorView *loadVideoActivity;

//当前播放时间
@property (nonatomic,assign)NSInteger currentPlayTime;

//剪切地址数组
@property (nonatomic,strong)NSMutableArray *shortCutArray;

@property (nonatomic,assign)NSInteger shortCutStartTime;

@property (nonatomic,assign)NSInteger shortCutTotalTime;

@property (nonatomic,assign)NSInteger shortCutDownloadCount;

@property (nonatomic,copy)NSString *shortCutFileName;

@property (nonatomic,strong)ACCaptureVideoDecoder *captureDecoder;

@property (nonatomic,strong)UIImageView *playButton;


@end

@implementation CloudPlayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configNav];
    [self getCloudVideoTime];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"3_A9976100KJ769WNWV3A6FYLB111A_201710250332220542" ofType:@"H264"];
    self.h264FilePath = path;
    self.view.backgroundColor = [UIColor whiteColor];
    _isPlaying = NO;
    self.title = @"云存储";
    [super viewDidLoad];
    _videoDecoder = [[ACCloudVideoDecoder alloc] init];
    _previewDecoder = [[ACSeekVideoDecoder alloc]init];
    _captureDecoder = [[ACCaptureVideoDecoder alloc]init];
    //获取token
//    [self getToken];
    [self.view addSubview:self.topView];
    
    //添加播放器view
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.playerView = [[GDPlayerView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_WIDTH * playViewRatio)];
        [self.topView addSubview:self.playerView];
        [self.playerView playViewSetup];
        self.playerView.backgroundColor = [UIColor blackColor];
    });

    //添加播放状态通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playStatusChange:) name:PlayStatusNotification object:nil];

    // 2.创建 AHRuler 对象 并设置代理对象
    self.ruler = [[AHRuler alloc] initWithFrame:CGRectMake(0, SCREEN_WIDTH * 9/16, [UIScreen mainScreen].bounds.size.width, 120)];
    self.ruler.rulerDeletate = self;
    
    //当前时间凌晨一点
    [self.ruler showRulerScrollViewWithAverage:rulerAverageTypeOne currentValue:3600];
    [self.view addSubview:self.ruler];
    
//    //预先存储好需要展示的数据
//    [self loadDateData];
    
    //添加dateButton
    [self.view addSubview:self.dateButton];
    
    // 初始化pickerView
    UIView *pickCoverView = [[UIView alloc]initWithFrame:CGRectMake(0, SCREEN_WIDTH * 9/16 + 120 + 60, self.view.bounds.size.width, 150)];
    pickCoverView.backgroundColor = [UIColor whiteColor];
    self.pickCoverView = pickCoverView;
    self.pickCoverView.hidden = YES;
    [self.view addSubview:pickCoverView];
    
    self.pickView = [[UIPickerView alloc]initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 150)];
    [self.pickCoverView addSubview:self.pickView];
    
    //指定数据源和委托
    self.pickView.delegate = self;
    self.pickView.dataSource = self;
    [self initBottomView];
    
    
    
    //初始化pcm播放器
    if (!_pcmPlayer) {
        _pcmPlayer = [[PCMPlayer alloc]init];
        [_pcmPlayer initOpenAL];
    }
    
    self.isHasSound = YES;
    //添加预览View
    [self.view addSubview:self.previewView];
    [self.previewView addSubview:self.playButton];
    [self.previewView addSubview:self.loadVideoActivity];
    self.isPlaying = NO;
//    [self decodeAndPlayVideo];
//    [self convertMP4];
    //解码播放
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [self decodeAndPlayVideo];
//    });
    
//    [self decodeAndPlayVideoWithSeekTime:0];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
     [self.videoDecoder ac_pause:NO];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.videoDecoder ac_pause:YES];
}


- (void)dealloc{
    NSLog(@"CloudVC被销毁了------------------------------------------");
}


- (void)configNav{
    
    UIImage *image = [UIImage imageNamed:@"addev_back"];
    EnlargeClickButton *button = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 0, 70, 40);
    button.imageEdgeInsets = UIEdgeInsetsMake(10, 0, 10, 50);
    [button setImage:image forState:UIControlStateNormal];
    [button addTarget:self
               action:@selector(navBack)
     forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    leftBarButtonItem.style = UIBarButtonItemStylePlain;
    self.navigationItem.leftBarButtonItem = leftBarButtonItem;
    
}


- (void)navBack{
    [self.pcmPlayer clearOpenAL];
    self.pcmPlayer = nil;
    [self.videoDecoder ac_uninit];
    self.videoDecoder = nil;
    [self.captureDecoder ac_uninit];
    self.captureDecoder = nil;
    [self.previewDecoder ac_uninit];
    self.previewDecoder = nil;
    [self.playerView removeFromSuperview];
    self.playerView = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.navigationController popViewControllerAnimated:YES];
    [self removeCacheFile];
}


//清除cache文件夹中的缓存
- (void)removeCacheFile{
    NSString *extension1 = @"H264";
    NSString *extension2 = @"jpg";
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:nil];
    NSEnumerator *enumerator = [contents objectEnumerator];
    NSString *filename;
    while ((filename = [enumerator nextObject])) {
        if ([[filename pathExtension] isEqualToString:extension1] || [[filename pathExtension] isEqualToString:extension2]) {
            [fileManager removeItemAtPath:[documentsDirectory stringByAppendingPathComponent:filename] error:nil];
        }
    }
}

//- (void)decodeAndPlayVideo{
//    __weak typeof(self) weakSelf = self;
//    //解码并且播放
//    [self.videoDecoder initVideoDecoderWithDataCallBack:^(PDecodedFrameParam frameParam) {
//        if (!frameParam) {
//            //重新开始解码264
//            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//                [self startToDecH264FileWithPort:0 filePath:_h264FilePath];
//            });
//            return ;
//        }
//        if ( frameParam->lpBuf == NULL)
//        {
//            return;
//        }
//        //        NSLog(@"VideoDecoderCallBack___________________width:%ld height:%ld size:%ld",frameParam->lWidth,frameParam->lHeight,frameParam->lSize);
//        if ( frameParam->nDecType == 0 ) {//YUV
//            if (self.currentSeekTimeIndex != INT_MAX) {
//                [self.videoDecoder seekToTime:self.currentSeekTimeIndex photoPath:[self getPreViewPhotoPath]];
//                self.currentSeekTimeIndex = INT_MAX;
//            }
//
//            @autoreleasepool {
//                //视频的大小
//                if ( frameParam->lWidth!=0 && _videoWidth != frameParam->lWidth) {
//                    _videoWidth = frameParam->lWidth;
//                    _videoHeight = frameParam->lHeight;
//                }
//                long imageSize = frameParam->lWidth * frameParam->lHeight;
//                //                NSData *yuvData = [NSData dataWithBytes:frameParam->lpBuf length: imageSize];
//                //交给播放器播放
//                if (!weakSelf.yuvFrame) {
//                    weakSelf.yuvFrame = [[KxVideoFrameYUV alloc]init];
//                }else{
//                    weakSelf.yuvFrame.luma = weakSelf.yuvFrame.chromaB = weakSelf.yuvFrame.chromaR = nil;
//                }
//                weakSelf.yuvFrame.width  = frameParam->lWidth;
//                weakSelf.yuvFrame.height = frameParam->lHeight;
//                weakSelf.yuvFrame.luma = [NSData dataWithBytes:frameParam->lpBuf length: imageSize];
//                weakSelf.yuvFrame.chromaB = [NSData dataWithBytes:frameParam->lpBuf+(int)imageSize length:imageSize/4];
//                weakSelf.yuvFrame.chromaR = [NSData dataWithBytes:frameParam->lpBuf+(int)(imageSize*5/4) length:imageSize/4];
//                //渲染视频
//                dispatch_async_on_main_queue(^{
//                    [weakSelf.playerView render:weakSelf.yuvFrame];
//                });
//            }
//        }
//        else if(frameParam ->nDecType == 4){
//            //音频数据播放
//            if (weakSelf.isHasSound) {
//                [weakSelf.pcmPlayer openAudioWithBuffer:frameParam->lpBuf length:frameParam->lSize];
//            }
//        }
//    }];
//    //开始解码h264文件
//    [self startToDecH264FileWithPort:0 filePath:_h264FilePath];
//
////    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
////        [self.previewDecoder seekToTime:10 photoPath:nil];
////    });
//
//
//}


- (void)convertMP4WithStartValue:(NSInteger)startValue totalValue:(NSInteger)totalValue fileName:(NSString *)fileName{

    //开始转换mp4
    self.shortCutTotalTime = totalValue;
    self.shortCutDownloadCount = totalValue / 5 + 2;
    self.shortCutFileName = [NSString stringWithFormat:@"%@.mp4",fileName];
    [self.shortCutArray removeAllObjects];
    
    //先获取开始的模型
    __block CloudPlayModel *playModel;
    [self.cloudPlayUrlArray enumerateObjectsUsingBlock:^(CloudPlayModel *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.accuracylastStamp >= startValue && obj.accuracyfirstStamp <= startValue) {
            playModel = obj;
            //seek时间点获取到
            self.shortCutStartTime = startValue - obj.accuracyfirstStamp;
            *stop = YES;
        }
    }];
    
    if (playModel) {
        //可以裁剪 --开始下载
        [self downloadConvertMp4FileWithModel:playModel];
    }
    else{
        //裁剪失败
        NSDictionary *notifyData = @{@"result":[NSNumber numberWithInt:0]
                                     };
        [[NSNotificationCenter defaultCenter] postNotificationName:ConvertMP4Notification object:nil userInfo:notifyData];
    }
    
}


- (void)downloadConvertMp4FileWithModel:(CloudPlayModel *)model{
    
    if ([self isFileExist:model.key]) {
        NSString *path = [self getPlayPathWithKey:model.key];
        [self.shortCutArray addObject:path];
        
        if (self.shortCutArray.count >= self.shortCutDownloadCount) {
            [self finallyConvertMp4];
        }
        else{
            CloudPlayModel *playModel = [self getNextModelWithPlayModel:model];
            if (playModel) {
                [self downloadConvertMp4FileWithModel:playModel];
            }
            else{
                [self finallyConvertMp4];
            }
        }
        return;
    }

    NSString * downloadUrl = [self getDownloadUrlWithBucketName:model.bucket ObjectKey:model.key];
    //创建传话管理者
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:downloadUrl]];
    //下载文件
    /*
     第一个参数:请求对象
     第二个参数:progress 进度回调
     第三个参数:destination 回调(目标位置)
     有返回值
     targetPath:临时文件路径
     response:响应头信息
     第四个参数:completionHandler 下载完成后的回调
     filePath:最终的文件路径
     */
    NSURLSessionDownloadTask *download = [manager downloadTaskWithRequest:request
                                                                 progress:^(NSProgress * _Nonnull downloadProgress) {
                                                                                                                                          //下载进度
                                                                                                                                          NSLog(@"%f",1.0 * downloadProgress.completedUnitCount / downloadProgress.totalUnitCount);
                                                                 }
                                                              destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
                                                                  //保存的文件路径
                                                                  NSString *fullPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[model.key stringByReplacingOccurrencesOfString:@"/" withString:@"_"]];
                                                                  return [NSURL fileURLWithPath:fullPath];
                                                              }
                                                        completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                                                            
                                                            
                                                            if (error) {
                                                                //剪切失败
                                                                NSDictionary *notifyData = @{@"result":[NSNumber numberWithInt:0]
                                                                                             };
                                                                [[NSNotificationCenter defaultCenter] postNotificationName:ConvertMP4Notification object:nil userInfo:notifyData];
                                                                return;
                                                            }
                                                            
                                                            //添加路径
                                                            [self.shortCutArray addObject:filePath.path];
                                                            //下载完成，不会去自动播放
                                                            if (self.shortCutArray.count >=self.shortCutDownloadCount) {
                                                                [self finallyConvertMp4];
                                                            }
                                                            else{
                                                                CloudPlayModel *nextModel = [self getNextModelWithPlayModel:model];
                                                                if (nextModel) {
                                                                    [self downloadConvertMp4FileWithModel:nextModel];
                                                                }
                                                                else{
                                                                    [self finallyConvertMp4];
                                                                }
                                                            }
                                                            
                                                        }];
    
    //执行Task
    [download resume];
    
}

- (NSString *)getMP4DestinationFileNamePathWith:(NSString *)fileName{
    return [[MediaManager shareManager] mediaPathWithDevId:[self.deviceId substringFromIndex:8] fileName:fileName mediaType:GosMediaShortCut deviceType:GosDeviceIPC position:PositionMain];
//    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
//    path = [path stringByAppendingPathComponent:@"GosDeviceIPC"];
//    path = [path stringByAppendingPathComponent:self.deviceId];
//    path = [path stringByAppendingPathComponent:@"Record"];
//    path = [path stringByAppendingPathComponent:fileName];
//    return path;
}


- (void)finallyConvertMp4{
    //先删除
    [self deleteFileWithPath:[self getConvertMP4Path]];
    
    //写文件
    NSMutableData *writer = [[NSMutableData alloc] init];
    
    for (NSString *pathStr in self.shortCutArray) {
        NSData *fileData = [NSData dataWithContentsOfFile:pathStr];
        [writer appendData:fileData];
    }
    
    [writer writeToFile:[self getConvertMP4Path] atomically:YES];
    
    [writer resetBytesInRange:NSMakeRange(0, writer.length)];
    
    [writer setLength:0];
    
    //开始裁剪
    [self.captureDecoder initVideoDecoderWithDataCallBack:^(PDecodedFrameParam frameParam) {
        
    }];
    [self.captureDecoder ac_captureMP4WithOrgFileName:[self getConvertMP4Path] destinaFileName:[self getMP4DestinationFileNamePathWith:self.shortCutFileName] startTime:self.shortCutStartTime totalTime:self.shortCutTotalTime];
}




#pragma mark - 播放状态change
- (void)playStatusChange:(NSNotification *)statusNotify{
    NSDictionary *statusDict = statusNotify.userInfo;
    
//
//    AVRecOpenSuccess        = 0,
//    AVRecOpenErr,
//    AVRecRetTime,
//    AVRecTimeEnd,
//    AVRetPlayRecTotalTime,
//    AVRetPlayRecTime,
//    AVRetPlayRecFinish,
//    AVRetPlayRecSeekCapture,
//    AVRetPlayRecRecordFinish,
    
    NSNumber * eventRec = (NSNumber *)statusDict[@"eventRec"];
    NSNumber * lData = (NSNumber *)statusDict[@"lData"];
    NSNumber * nPort = (NSNumber *)statusDict[@"nPort"];
    NSNumber * lUserParam = (NSNumber *)statusDict[@"lUserParam"];
    ACVideoDecoder *videoDecode = statusDict[@"Decode"];
    
    if (eventRec.intValue == 5 && videoDecode == self.videoDecoder) {
        //更新进度
        int playValue = self.currentActurePlayModel.accuracyfirstStamp + lData.longValue;
        self.currentPlayTime = playValue;
        dispatch_async_on_main_queue(^{
            [self.ruler.rulerScrollView drawCurrentIndicatorWithValue:playValue];
//            [self.ruler setContentOffSetWithValue:playValue];
        });
        //播放时间
        NSLog(@"播放时间----%ld",lData.longValue);
    }
    
    if (eventRec.intValue == 6 && videoDecode == self.videoDecoder) {
        //播放结束
        //先干掉之前的额
        CloudPlayModel *nextPlayModel = [self getNextModelWithPlayModel:self.currentActurePlayModel];
        if (nextPlayModel) {
            [self playNextModel:nextPlayModel];
        }
    }
    
    if (eventRec.intValue == 4 && videoDecode == self.previewDecoder) {
        //可以seek了
        if (self.currentPreviewSeekTimeIndex != INT_MAX) {
            if (self.currentPreviewSeekTimeIndex >5) {
                self.currentPreviewSeekTimeIndex = 5;
            }
            //seek到指定位置
            //开始seek --先删除缓存图片
            NSLog(@"SeekABC 读取文件成功，时间为%d-----------------------------------------------",self.currentPreviewSeekTimeIndex);
            [self deleteFilePhotoPathWithPlayModel:self.currentSeekModel];
            [self.previewDecoder seekToTime:self.currentPreviewSeekTimeIndex photoPath:[self getPreViewPhotoPathWithPlayModel:self.currentSeekModel]];
            self.currentPreviewSeekTimeIndex = INT_MAX;
        }
    }
    
  
    if (eventRec.intValue == 7 && videoDecode == self.previewDecoder) {
        NSLog(@"SeekABC 成功-----------------------------------------------");
        dispatch_async_on_main_queue(^{
            //停止解码 --//获取预览图
            //停止这个端口的解码
            [self.previewDecoder ac_stopDecH264FileWithPort:nPort.intValue];
            UIImage *preViewImage = [UIImage imageWithContentsOfFile:[self getPreViewPhotoPathWithPlayModel:self.currentSeekModel]];
            if (preViewImage) {
                //存在预览图
                NSLog(@"预览图存在，并且成功获取了");
                [self.previewView setBackgroundImage:preViewImage forState:UIControlStateNormal];
                self.previewView.userInteractionEnabled = YES;
                self.previewView.hidden = NO;
                [self.view bringSubviewToFront:self.previewView];
                self.loadVideoActivity.hidden = YES;
                self.playButton.hidden = NO;
            }
        });
    }
}

//- (void)convertMP4{
//    _videoDecoder = [[ACVideoDecoder alloc] init];
//     [self.videoDecoder initVideoDecoderWithDataCallBack:^(PDecodedFrameParam frameParam) {
//
//     }];
//    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
//    path = [path stringByAppendingPathComponent:@"test23456988989.mp4"];
//    [_videoDecoder ac_captureMP4WithOrgFileName:self.h264FilePath destinaFileName:path startTime:5 totalTime:-1];
//}


//- (void)decodeAndPlayVideoWithSeekTime:(NSInteger)seekTime{
//    dispatch_async_on_main_queue(^{
//        //先停止解码
//        [self.videoDecoder ac_stopDecode];
//        __weak typeof(self) weakSelf = self;
//        //解码并且播放
//        [self.videoDecoder initVideoDecoderWithDataCallBack:^(PDecodedFrameParam frameParam) {
//            if ( frameParam->lpBuf == NULL)
//            {
//                return;
//            }
//            if ( frameParam->nDecType == 0 ) {//YUV
//                @autoreleasepool {
//                    //视频的大小
//                    long imageSize = frameParam->lWidth * frameParam->lHeight;
//                    //                NSData *yuvData = [NSData dataWithBytes:frameParam->lpBuf length: imageSize];
//                    //交给播放器播放
//                    if (!weakSelf.yuvFrame) {
//                        weakSelf.yuvFrame = [[KxVideoFrameYUV alloc]init];
//                    }else{
//                        weakSelf.yuvFrame.luma = weakSelf.yuvFrame.chromaB = weakSelf.yuvFrame.chromaR = nil;
//                    }
//                    weakSelf.yuvFrame.width  = frameParam->lWidth;
//                    weakSelf.yuvFrame.height = frameParam->lHeight;
//                    weakSelf.yuvFrame.luma = [NSData dataWithBytes:frameParam->lpBuf length: imageSize];
//                    weakSelf.yuvFrame.chromaB = [NSData dataWithBytes:frameParam->lpBuf+(int)imageSize length:imageSize/4];
//                    weakSelf.yuvFrame.chromaR = [NSData dataWithBytes:frameParam->lpBuf+(int)(imageSize*5/4) length:imageSize/4];
//                    //渲染视频
//                    dispatch_async_on_main_queue(^{
//                        [weakSelf.playerView render:weakSelf.yuvFrame];
//                    });
//                }
//            }
//            else if(frameParam ->nDecType == 4){
//                //音频数据播放
//                if (weakSelf.isHasSound) {
//                    [weakSelf.pcmPlayer openAudioWithBuffer:frameParam->lpBuf length:frameParam->lSize];
//                }
//            }
//        }];
//        //开始解码h264文件
//        [self.videoDecoder ac_startDecH264FileWithPort:0 filePath:_h264FilePath];
//    });
//
//}


- (void)decodeAndPlayVideoWithSeekTime:(NSInteger)seekTime{
    if (self.currentActurePlayModel == self.currentPlayModel) {
        //直接seek
        [self.videoDecoder seekToTime:seekTime photoPath:nil];
    }
    else{
        //切换播放
        dispatch_async_on_main_queue(^{
            self.currentActurePlayModel = self.currentPlayModel;
            self.h264FilePath = [self getPlayPathWithKey:self.currentPlayModel.key];
            //先停止解码
            [self.videoDecoder ac_stopDecode];
            __weak typeof(self) weakSelf = self;
            //解码并且播放
            [self.videoDecoder initVideoDecoderWithDataCallBack:^(PDecodedFrameParam frameParam) {
                if ( frameParam->lpBuf == NULL)
                {
                    return;
                }
                //        NSLog(@"VideoDecoderCallBack___________________width:%ld height:%ld size:%ld",frameParam->lWidth,frameParam->lHeight,frameParam->lSize);
                if ( frameParam->nDecType == 0 ) {//YUV
                    if (weakSelf.currentPreviewCacheSeekTimeIndex != INT_MAX) {
                        if (weakSelf.currentPreviewCacheSeekTimeIndex >5) {
                            weakSelf.currentPreviewCacheSeekTimeIndex = 5;
                        }
                        //开始seek
                        [weakSelf.videoDecoder seekToTime:weakSelf.currentPreviewCacheSeekTimeIndex photoPath:nil];
                        weakSelf.currentPreviewCacheSeekTimeIndex = INT_MAX;
                    }
                    
                    @autoreleasepool {
                        //视频的大小
                        //                    if ( frameParam->lWidth!=0 && _videoWidth != frameParam->lWidth) {
                        //                        _videoWidth = frameParam->lWidth;
                        //                        _videoHeight = frameParam->lHeight;
                        //                    }
                        long imageSize = frameParam->lWidth * frameParam->lHeight;
                        //                NSData *yuvData = [NSData dataWithBytes:frameParam->lpBuf length: imageSize];
                        //交给播放器播放
                        if (!weakSelf.yuvFrame) {
                            weakSelf.yuvFrame = [[KxVideoFrameYUV alloc]init];
                        }else{
                            weakSelf.yuvFrame.luma = weakSelf.yuvFrame.chromaB = weakSelf.yuvFrame.chromaR = nil;
                        }
                        weakSelf.yuvFrame.width  = frameParam->lWidth;
                        weakSelf.yuvFrame.height = frameParam->lHeight;
                        weakSelf.yuvFrame.luma = [NSData dataWithBytes:frameParam->lpBuf length: imageSize];
                        weakSelf.yuvFrame.chromaB = [NSData dataWithBytes:frameParam->lpBuf+(int)imageSize length:imageSize/4];
                        weakSelf.yuvFrame.chromaR = [NSData dataWithBytes:frameParam->lpBuf+(int)(imageSize*5/4) length:imageSize/4];
                        //渲染视频
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [weakSelf.playerView render:weakSelf.yuvFrame];
                        });
                    }
                }
                else if(frameParam ->nDecType == 4){
                    //音频数据播放
                    if (weakSelf.isHasSound) {
                        [weakSelf.pcmPlayer openAudioWithBuffer:frameParam->lpBuf length:frameParam->lSize];
                    }
                }
            }];
            //开始解码h264文件
            [self.videoDecoder ac_startDecH264FileWithPort:0 filePath:_h264FilePath];
        });
    }
    //再缓存下载下一个
    CloudPlayModel *nextPlayModel = [self getNextModelWithPlayModel:self.currentPlayModel];
    if (nextPlayModel) {
        [self downloadH264FileWithModel:nextPlayModel];
    }
}


- (void)initBottomView{

    [self.view addSubview:self.bottomView];
    [self.view insertSubview:self.bottomView atIndex:0];
    [self.bottomView addSubview:self.soundBtn];
    [self.bottomView addSubview:self.shortCutBtn];
    [self.bottomView addSubview:self.snapshotBtn];
    
    [self.bottomView addSubview:self.soundLabel];
    [self.bottomView addSubview:self.shortCutLabel];
    [self.bottomView addSubview:self.snapshotLabel];
    
    CGFloat screenHeight = [[UIScreen mainScreen] bounds].size.height;
    CGFloat screenWidth = [[UIScreen mainScreen] bounds].size.width;
    //真实屏幕宽度
    CGFloat playHeight = trueSreenWidth *playViewRatio;
    CGFloat bottomHeight = (MAX(screenWidth, screenHeight) - 64.0f - playHeight - 200);
    [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view);
        //这里添加40
        make.height.mas_equalTo(bottomHeight + 40);
        make.left.right.equalTo(self.view);
    }];
    
    //计算按钮大小 默认对讲按钮是两倍声音按钮大
    CGFloat bottomBtnWH;
    bottomBtnWH = (trueSreenWidth - 32 - 64)/4.0f;
    [self.soundBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.bottomView.mas_centerY);
        make.left.equalTo(self.bottomView).offset(16);
        make.height.width.mas_equalTo(bottomBtnWH);
    }];
    
    [self.shortCutBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.bottomView.mas_centerY);
        make.left.equalTo(self.soundBtn.mas_right).offset(32);
        make.height.width.mas_equalTo(2 * bottomBtnWH);
    }];
    
    [self.snapshotBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.bottomView.mas_centerY);
        make.left.equalTo(self.shortCutBtn.mas_right).offset(32);
        make.height.width.mas_equalTo(bottomBtnWH);
    }];
    
    [self.soundLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.soundBtn);
        make.height.equalTo(@20);
        make.width.equalTo(@100);
        make.top.equalTo(self.soundBtn.mas_bottom).offset(5);
    }];
    
    [self.shortCutLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.shortCutBtn);
        make.height.equalTo(@20);
        make.width.equalTo(@100);
        make.top.equalTo(self.shortCutBtn.mas_bottom).offset(-5);
    }];
    
    [self.snapshotLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.snapshotBtn);
        make.height.equalTo(@20);
        make.width.equalTo(@100);
        make.top.equalTo(self.snapshotBtn.mas_bottom).offset(5);
    }];
    
}


#pragma mark - ahRuler Delegate
- (void)ahRuler:(AHRulerScrollView *)rulerScrollView {
    NSString *text = [self getTimeTextWithValue:rulerScrollView.rulerValue];
}


- (void)ahRulerEndDrag:(AHRulerScrollView *)rulerScrollView{
    //停止拖动，去获取预览图
    [self getPlayPreviewWithValue:rulerScrollView.rulerValue];
}

#pragma mark - 工具方法
- (void)getPlayPreviewWithValue:(NSInteger)selectValue{
//    [self delayHiddenPreView];
    self.loadVideoActivity.hidden = NO;
     self.playButton.hidden = YES;
    
    //遍历寻找播放模型
    __block CloudPlayModel *playModel;
    
    __weak typeof(self) weakSelf = self;
    
    [self.cloudPlayUrlArray enumerateObjectsUsingBlock:^(CloudPlayModel *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.accuracylastStamp >= selectValue && obj.accuracyfirstStamp <= selectValue) {
            weakSelf.currentSeekModel = obj;
            playModel = obj;
            //seek时间点获取到
            weakSelf.currentPreviewSeekTimeIndex = selectValue - obj.accuracyfirstStamp;
            weakSelf.currentPreviewCacheSeekTimeIndex = selectValue - obj.accuracyfirstStamp;
            *stop = YES;
        }
    }];
    
    if (playModel) {
        //存在录制视频
        weakSelf.previewView.hidden = NO;
        weakSelf.currentSeekModel = playModel;
        //seek到这个位置并且缓存一个
        [weakSelf seekToTime:weakSelf.currentPreviewSeekTimeIndex playModel:playModel];
    }
    else{
        //不存在录制视频
        weakSelf.previewView.hidden = YES;
    }

}


- (void)delayHiddenPreView{
    [self performSelector:@selector(hiddenPreViewBtn) withObject:nil afterDelay:5];
     [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hiddenPreViewBtn) object:nil];
    
}


- (void)hiddenPreViewBtn{
    self.previewView.hidden = YES;
    self.previewView.userInteractionEnabled = NO;
}


- (void)seekToTime:(NSInteger)seekTime playModel:(CloudPlayModel *)playModel{
    //下载视频 并且seek到指定时间点 设置预览图
    if ([self isFileExist:playModel.key]) {
        //如果存在直接开始播放
        //渲染预览图
        [self seekFileAndGetPreviewWithModel:playModel seekTime:seekTime];
    }
    else{
        //下载播放
        NSString * downloadUrl = [self getDownloadUrlWithBucketName:playModel.bucket ObjectKey:playModel.key];
        //创建传话管理者
        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:downloadUrl]];
        //下载文件
        /*
         第一个参数:请求对象
         第二个参数:progress 进度回调
         第三个参数:destination 回调(目标位置)
         有返回值
         targetPath:临时文件路径
         response:响应头信息
         第四个参数:completionHandler 下载完成后的回调
         filePath:最终的文件路径
         */
        NSURLSessionDownloadTask *download = [manager downloadTaskWithRequest:request
                                                                     progress:^(NSProgress * _Nonnull downloadProgress) {
                                                                         //下载进度
                                                                         NSLog(@"%f",1.0 * downloadProgress.completedUnitCount / downloadProgress.totalUnitCount);
                                                                     }
                                                                  destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
                                                                      //保存的文件路径
                                                                      NSString *fullPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[playModel.key stringByReplacingOccurrencesOfString:@"/" withString:@"_"]];
                                                                      return [NSURL fileURLWithPath:fullPath];
                                                                  }
                                                            completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                                                                //下载完成，去seek播放
//                                                                self.h264FilePath = filePath.path;
                                                                //判断一下是否当时还是选中的这个，如果是的，渲染一下预览图
                                                                if (self.currentSeekModel == playModel) {
                                                                    [self seekFileAndGetPreviewWithModel:playModel seekTime:seekTime];
                                                                }
                                                            }];
        
        //执行Task
        [download resume];
    }
}


- (void)playNextModel:(CloudPlayModel *)playModel{
    
    //设置当前播放模型
    self.currentPlayModel = playModel;
    
    NSLog(@"nextModel--------------------------------%@",playModel.key);
    
    //自动播放下一个视频
    if ([self isFileExist:playModel.key]) {
        //如果存在直接开始播放
        [self decodeAndPlayVideoWithSeekTime:0];
    }
    else{
        //下载播放
        NSString * downloadUrl = [self getDownloadUrlWithBucketName:playModel.bucket ObjectKey:playModel.key];
        //创建传话管理者
        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:downloadUrl]];
        //下载文件
        /*
         第一个参数:请求对象
         第二个参数:progress 进度回调
         第三个参数:destination 回调(目标位置)
         有返回值
         targetPath:临时文件路径
         response:响应头信息
         第四个参数:completionHandler 下载完成后的回调
         filePath:最终的文件路径
         */
        NSURLSessionDownloadTask *download = [manager downloadTaskWithRequest:request
                                                                     progress:^(NSProgress * _Nonnull downloadProgress) {
                                                                         //下载进度
                                                                         NSLog(@"%f",1.0 * downloadProgress.completedUnitCount / downloadProgress.totalUnitCount);
                                                                     }
                                                                  destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
                                                                      //保存的文件路径
                                                                      NSString *fullPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[playModel.key stringByReplacingOccurrencesOfString:@"/" withString:@"_"]];
                                                                      return [NSURL fileURLWithPath:fullPath];
                                                                  }
                                                            completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                                                                //下载完成，去自动播放 如果还是播放这一个的话
                                                                if (self.currentPlayModel == playModel) {
                                                                    [self decodeAndPlayVideoWithSeekTime:0];
                                                                }
                                                            }];
        
        //执行Task
        [download resume];
    }
    
}


- (void)seekFileAndGetPreviewWithModel:(CloudPlayModel *)playModel seekTime:(NSInteger)seekTime{
    //停止上一个解码
    [self.previewDecoder ac_stopDecode];
    
    NSLog(@"SeekABC 开始-----------------------------------------------");
    //初始化
    [self.previewDecoder initVideoDecoderWithDataCallBack:^(PDecodedFrameParam frameParam) {
    }];
    [self.previewDecoder ac_startDecH264FileWithPort:0 filePath:[self getPlayPathWithKey:playModel.key]];
}


- (void)deleteFilePhotoPathWithPlayModel:(CloudPlayModel *)playModel{
    
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSString *fileFullPath = [self getPreViewPhotoPathWithPlayModel:playModel];
     BOOL bRet = [fileMgr fileExistsAtPath:fileFullPath];
    if (bRet) {
        //删除
        [fileMgr removeItemAtPath:fileFullPath error:nil];
    }
    
}


- (void)deleteFileWithPath:(NSString *)path{
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    BOOL bRet = [fileMgr fileExistsAtPath:path];
    if (bRet) {
        //删除
        [fileMgr removeItemAtPath:path error:nil];
    }
}


- (NSString *)getConvertMP4Path{
    return [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"ACEDONG_0806.H264"];
}

- (NSString *)getPreViewPhotoPathWithPlayModel:(CloudPlayModel *)playModel{
    return [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[[playModel.key stringByReplacingOccurrencesOfString:@"/" withString:@"_"] stringByReplacingOccurrencesOfString:@".H264" withString:@".jpg"]];
}


- (CloudPlayModel *)getNextModelWithPlayModel:(CloudPlayModel *)playModel{
    NSInteger index = [self.cloudPlayUrlArray indexOfObject:playModel];
    if (index + 1 < self.cloudPlayUrlArray.count) {
        return self.cloudPlayUrlArray[index +1];
    }
    return nil;
}


- (void)loadDateDataWithDays:(int)days{
    self.dateArray = [NSMutableArray array];
    NSDate* currentDate = [NSDate dateWithTimeIntervalSinceNow:0];
    //转换为当天零点date
    currentDate = [self getZeroDateWithCurrentDate:currentDate];
    self.currentSelectDate = currentDate;
    self.ruler.rulerScrollView.selectDate = self.currentSelectDate;
    [self.dateButton setTitle:[self getDateStringWithDate:currentDate] forState:UIControlStateNormal];
    [self.dateArray addObject:currentDate];
    for (int i = 0;i < days;i++) {
        NSDate *lastDate = [NSDate dateWithTimeInterval:-24*60*60*(i+1) sinceDate:currentDate];//前一天
        [self.dateArray addObject:lastDate];
    }
}


//获取云存储套餐时长
- (void)getCloudVideoTime{
    [[AFHTTPSessionManager manager] GET:@"http://119.23.124.137:9998/api/cloudstore/cloudstore-service/service/data-valid" parameters:@{@"token" : [mUserDefaults objectForKey:USER_TOKEN],@"device_id" : self.deviceId,@"username":[SaveDataModel getUserName]} progress:^(NSProgress * _Nonnull uploadProgress) {
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        //获取套餐时长数据
        NSArray *dataArray = responseObject[@"data"];
        if ([dataArray isKindOfClass:[NSArray class]]) {
            if (dataArray.count >0) {
                NSDictionary *dataDict = dataArray[0];
                NSNumber *dataLifeNumber = dataDict[@"dateLife"];
                [self loadDateDataWithDays:dataLifeNumber.intValue];
                //刷新数据
                [self.pickView reloadAllComponents];
                [self getToken];
            }
            else{
                [SVProgressHUD showErrorWithStatus:@"未开通云存储套餐"];
                [SVProgressHUD dismissWithDelay:1.0f];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self.navigationController popViewControllerAnimated:YES];
                });
            }
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [SVProgressHUD showErrorWithStatus:@"数据加载失败"];
    }];
}



//获取云存储token
- (void)getToken{
    [SVProgressHUD showWithStatus:DPLocalizedString(@"loading")];
//    NSString *token = [mUserDefaults objectForKey:USER_TOKEN];
//    NSString *userName = [SaveDataModel getUserName];
//    NSString *deviceId = self.deviceId;
    [[AFHTTPSessionManager manager] POST:@"http://119.23.124.137:9998/api/cloudstore/cloudstore-service/sts/check-token" parameters:@{@"token" : [mUserDefaults objectForKey:USER_TOKEN],@"device_id" : self.deviceId,@"username":[SaveDataModel getUserName]} progress:^(NSProgress * _Nonnull uploadProgress) {
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        self.tokenDict = responseObject[@"data"];
        //请求一次当前数据
        [self getcurrentVideoData];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [SVProgressHUD dismiss];
//        NSLog(@"%@",error.description);
    }];
}

- (void)getcurrentVideoData{
    //获取视频录制记录
    [[AFHTTPSessionManager manager] GET:[self getAlarmUrlByStartTime:self.currentSelectDate endTime:[self getNextDayWithDate:self.currentSelectDate]] parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"视频录制记录%@",responseObject);
        NSArray *dataArray = responseObject[@"data"];
        if ([responseObject[@"data"] isKindOfClass:[NSArray class]]) {
            //获取视频切片数据
            [self handleVideoArrayData:dataArray];
        }

    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"获取视频录制记录失败");
    }];
    
    //获取报警数据
//    [[AFHTTPSessionManager manager] GET:[self getAlarmUrlByStartTime:self.currentSelectDate endTime:[self getNextDayWithDate:self.currentSelectDate]] parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
//
//    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
//        NSArray *dataArray = responseObject[@"data"];
//
//        [self handleAlarmArrayData:dataArray];
//        if ([responseObject[@"data"] isKindOfClass:[NSArray class]]) {
//        }
//    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
//         NSLog(@"获取报警数据记录失败");
//    }];

    //获取播放ts片段url数据
    [[AFHTTPSessionManager manager] GET:[self getPlayListUrlWithStartByStartTime:self.currentSelectDate endTime:[self getNextDayWithDate:self.currentSelectDate]] parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {

    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSArray *dataArray = responseObject[@"data"];
        //解析出url数组
         NSLog(@"视频ts数据%@",responseObject);
        [self handleVideoUrlArrayData:dataArray];
        [SVProgressHUD dismiss];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"获取ts数据记录失败");
        [SVProgressHUD dismiss];
    }];
}


- (void)handleVideoUrlArrayData:(NSArray *)dataArray{
    if (dataArray.count > 0) {
        [self.cloudPlayUrlArray removeAllObjects];
        for (NSDictionary *dict in dataArray) {
            //转换模型数组
            CloudPlayModel *videoModel = [CloudPlayModel yy_modelWithDictionary:dict];
            [self.cloudPlayUrlArray addObject:videoModel];
        }
    }
    
    //进行疯狂计算--转换为今天的秒数
    for (CloudPlayModel *playModel in self.cloudPlayUrlArray) {
        long long accuracyfirstStamp = playModel.startTime - [self.currentSelectDate timeIntervalSince1970];
        long long accuracylastStamp = playModel.endTime - [self.currentSelectDate timeIntervalSince1970];
        playModel.accuracyfirstStamp = accuracyfirstStamp;
        playModel.accuracylastStamp = accuracylastStamp;
    }
    
//    if (self.cloudPlayUrlArray.count >0) {
//        CloudPlayModel *playModel =self.cloudPlayUrlArray[2];
//        [self downloadH264FileWithModel:playModel];
//    }
}


- (void)downloadH264FileWithModel:(CloudPlayModel *)playModel{
    if ([self isFileExist:playModel.key]) {
        self.h264FilePath = [self getPlayPathWithKey:playModel.key];
        return;
    }
    NSString * downloadUrl = [self getDownloadUrlWithBucketName:playModel.bucket ObjectKey:playModel.key];
    //创建传话管理者
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:downloadUrl]];
    //下载文件
    /*
     第一个参数:请求对象
     第二个参数:progress 进度回调
     第三个参数:destination 回调(目标位置)
     有返回值
     targetPath:临时文件路径
     response:响应头信息
     第四个参数:completionHandler 下载完成后的回调
     filePath:最终的文件路径
     */
    NSURLSessionDownloadTask *download = [manager downloadTaskWithRequest:request
                                                                 progress:^(NSProgress * _Nonnull downloadProgress) {
//                                                                     //下载进度
//                                                                     NSLog(@"%f",1.0 * downloadProgress.completedUnitCount / downloadProgress.totalUnitCount);
                                                                 }
                                                              destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
                                                                  //保存的文件路径
                                                                  NSString *fullPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[playModel.key stringByReplacingOccurrencesOfString:@"/" withString:@"_"]];
                                                                  return [NSURL fileURLWithPath:fullPath];
                                                              }
                                                        completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                                                            //下载完成，不会去自动播放
//                                                            self.h264FilePath = filePath.path;
//                                                            NSLog(@"%@",filePath.path);
                                                        }];
    
    //执行Task
    [download resume];
}


//判断H264文件是否已经存在
-(BOOL)isFileExist:(NSString *)fileName
{
    fileName = [fileName stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    NSString *filePath = [path stringByAppendingPathComponent:fileName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL result = [fileManager fileExistsAtPath:filePath];
    return result;
}


//获取H264文件路径
- (NSString *)getPlayPathWithKey:(NSString *)fileName{
    fileName = [fileName stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    NSString *fullPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:fileName];
    return fullPath;
}

- (void)handleVideoArrayData:(NSArray *)dataArray{
    if (dataArray.count > 0) {
        [self.cloudVideoArray removeAllObjects];
        for (NSDictionary *dict in dataArray) {
            //转换模型数组
            CloudVideoModel *videoModel = [CloudVideoModel yy_modelWithDictionary:dict];
            [self.cloudVideoArray addObject:videoModel];
        }
    }
    if (self.cloudVideoArray.count > 0) {
    }
    //进行疯狂计算--转换为今天的秒数
    for (CloudVideoModel *videoModel in self.cloudVideoArray) {
        long long accuracyfirstStamp = videoModel.startTime - [self.currentSelectDate timeIntervalSince1970];
        long long accuracylastStamp = videoModel.endTime - [self.currentSelectDate timeIntervalSince1970];
        videoModel.accuracyfirstStamp = accuracyfirstStamp;
        videoModel.accuracylastStamp = accuracylastStamp;
    }
    //时间赶，先这样写吧 --赋值数组
    self.ruler.rulerScrollView.selectDate = self.currentSelectDate;
    self.ruler.rulerScrollView.videoArray = self.cloudVideoArray;
}


- (void)handleAlarmArrayData:(NSArray *)dataArray{
    if (dataArray.count > 0) {
        [self.cloudAlarmArray removeAllObjects];
        for (NSDictionary *dict in dataArray) {
            //转换模型数组
            CloudAlarmModel *alarmModel = [CloudAlarmModel yy_modelWithDictionary:dict];
            [self.cloudAlarmArray addObject:alarmModel];
        }
    }
    //进行疯狂计算--转换为今天的秒数
    for (CloudAlarmModel *alarmModel in self.cloudAlarmArray) {
        long long timeStamp = alarmModel.timeStamp - [self.currentSelectDate timeIntervalSince1970];
        alarmModel.accuracyTimeStamp = timeStamp;
    }
    //赋值数组
    self.ruler.rulerScrollView.selectDate = self.currentSelectDate;
    self.ruler.rulerScrollView.moveDetectArray = self.cloudAlarmArray;
}

- (void)handleResuleWithTask:(OSSTask *)ossTask{
    NSLog(@"%@",ossTask.result);
}



- (NSString *)getTimeTextWithValue:(NSUInteger)TimeValue{
    NSString *timeText;
    int hrs = (int)TimeValue / 3600;
    int totolSecond = (int)TimeValue % 3600;
    int min = (int)totolSecond / 60;
    int second = (int)totolSecond % 60;
    timeText = [NSString stringWithFormat:@"%02d : %02d : %02d",hrs,min,second];
    return timeText;
}


//获取裸流切片url
- (NSString *)getPlayListUrlWithStartByStartTime:(NSDate *)startDate endTime:(NSDate *)endDate{
    long long startTime=(long long)[startDate timeIntervalSince1970];
    long long endTime=(long long)[endDate timeIntervalSince1970];
    NSString *urlStr = [NSString stringWithFormat:@"http://119.23.124.137:9998/api/cloudstore/cloudstore-service/move-video/time-line/details?device_id=%@&start_time=%lld&end_time=%lld&token=%@&username=%@",self.deviceId,startTime,endTime,[mUserDefaults objectForKey:USER_TOKEN],[SaveDataModel getUserName]];
    return urlStr;
}

//获取报警查询时间url
- (NSString *)getAlarmUrlByStartTime:(NSDate *)startDate endTime:(NSDate *)endDate{
    long long startTime=(long long)[startDate timeIntervalSince1970];
    long long endTime=(long long)[endDate timeIntervalSince1970];
    NSString *urlStr = [NSString stringWithFormat:@"http://119.23.124.137:9998/api/cloudstore/cloudstore-service/move-video/time-line?device_id=%@&start_time=%lld&end_time=%lld&token=%@&username=%@",self.deviceId,startTime,endTime,[mUserDefaults objectForKey:USER_TOKEN],[SaveDataModel getUserName]];
    return urlStr;
}


//获取视频录制时间url
- (NSString *)getVideoUrlByStartTime:(NSDate *)startDate endTime:(NSDate *)endDate{
    long long startTime=(long long)[startDate timeIntervalSince1970];
    long long endTime=(long long)[endDate timeIntervalSince1970];
    NSString *urlStr = [NSString stringWithFormat:@"http://119.23.124.137:9998/api/cloudstore/cloudstore-service/move-video/time-line?device_id=%@&start_time=%lld&end_time=%lld&token=%@&username=%@",self.deviceId,startTime,endTime,[mUserDefaults objectForKey:USER_TOKEN],[SaveDataModel getUserName]];
    return urlStr;
}


//获取后一天的date
- (NSDate *)getLastDayWithDate:(NSDate *)date{
    return [NSDate dateWithTimeInterval:-24*60*60 sinceDate:date];//前一天
}

//获取前一天的date
- (NSDate *)getNextDayWithDate:(NSDate *)date{
    return [NSDate dateWithTimeInterval:+24*60*60 sinceDate:date];//前一天
}

//nadate转nsstring
- (NSString *)getDateStringWithDate:(NSDate *)date {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    NSString *dateTime = [formatter stringFromDate:date];
    return dateTime;
}


//nsstring转nadate
- (NSDate *)dateFromString:(NSString *)dateString {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat: @"yyyy-MM-dd"];
    NSDate *destDate= [dateFormatter dateFromString:dateString];
    return destDate;
}


//获取当天零点nsdate
- (NSDate *)getZeroDateWithCurrentDate:(NSDate *)currentDate{
    NSString *dateString = [self getDateStringWithDate:currentDate];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat: @"yyyy-MM-dd"];
    NSDate *zeroDate= [dateFormatter dateFromString:dateString];
    return zeroDate;
}


//获取播放url
//- (NSString *)getPlayUrlWithBucketName:(NSString *)bucketName ObjectKey:(NSString *)objectKey{
//    if (!self.tokenDict) {
//        return nil;
//    }
//    NSString *key = self.tokenDict[@"key"];
//    NSString *security = self.tokenDict[@"secret"];
//    NSString *token = self.tokenDict[@"token"];
//    NSString *endpoint = @"http://oss-cn-shanghai.aliyuncs.com";
//    id<OSSCredentialProvider> credential = [[OSSStsTokenCredentialProvider alloc] initWithAccessKeyId:key secretKeyId:security securityToken:token];
//    OSSClientConfiguration * conf = [OSSClientConfiguration new];
//    conf.maxRetryCount = 2;
//    conf.timeoutIntervalForRequest = 30;
//    conf.timeoutIntervalForResource = 24 * 60 * 60;;
//    self.client = [[OSSClient alloc] initWithEndpoint:endpoint credentialProvider:credential clientConfiguration:conf];
//    NSDictionary *params = @{@"x-oss-process" : @"hls/sign"};;
//    OSSTask *mytask = [self.client presignConstrainURLWithBucketName:bucketName withObjectKey:objectKey withExpirationInterval:3600 withParameters:params];
//    return mytask.result;
//}

- (NSString *)getDownloadUrlWithBucketName:(NSString *)bucketName ObjectKey:(NSString *)objectKey{
    if (!self.tokenDict) {
        return nil;
    }
    NSString *key = self.tokenDict[@"key"];
    NSString *security = self.tokenDict[@"secret"];
    NSString *token = self.tokenDict[@"token"];
    NSString *endpoint = self.tokenDict[@"endPoint"];
    id<OSSCredentialProvider> credential = [[OSSStsTokenCredentialProvider alloc] initWithAccessKeyId:key secretKeyId:security securityToken:token];
    OSSClientConfiguration * conf = [OSSClientConfiguration new];
    conf.maxRetryCount = 2;
    conf.timeoutIntervalForRequest = 30;
    conf.timeoutIntervalForResource = 24 * 60 * 60;;
    self.client = [[OSSClient alloc] initWithEndpoint:endpoint credentialProvider:credential clientConfiguration:conf];
    OSSTask *mytask = [self.client presignConstrainURLWithBucketName:bucketName withObjectKey:objectKey withExpirationInterval:3600];
    return mytask.result;
}


- (void)playWithUrl:(NSString *)urlStr{

}



#pragma mark - Event Handle

- (void)playBtnClick{
    _isPlaying = YES;
    self.currentPlayModel = self.currentSeekModel;
    self.previewView.hidden = YES;
    self.previewView.userInteractionEnabled = NO;
    [self decodeAndPlayVideoWithSeekTime:self.currentPreviewCacheSeekTimeIndex];
}

- (void)snapshotBtnAction:(UIButton *)btn{
    //保存图片
    [self saveVideoScreenShot];
}

- (void)shortCutAction:(UIButton *)btn{
    CloudShortCutViewController *shortCutVC = [[CloudShortCutViewController alloc]init];
    shortCutVC.deviceId = self.deviceId;
    shortCutVC.cloudPlayVC = self;
    shortCutVC.currentSelectDate = self.currentSelectDate;
    shortCutVC.currentShortCutTime = self.currentPlayTime;
    [self.navigationController pushViewController:shortCutVC animated:YES];
}

- (void)soundBtnAction:(UIButton *)btn{
    btn.selected = !btn.selected;
    if (btn.selected) {
        //暂停声音
        _isHasSound = NO;
        [self.pcmPlayer stopSound];
        [_soundBtn setImage:[UIImage imageNamed:@"PlayNoSoundNormal"] forState:UIControlStateNormal];
        [_soundBtn setImage:[UIImage imageNamed:@"PlayNoSoundSelected"] forState:UIControlStateHighlighted];
    }
    else{
        //打开声音
        _isHasSound = YES;
        [_soundBtn setImage:[UIImage imageNamed:@"PlaySoundNormal"] forState:UIControlStateNormal];
        [_soundBtn setImage:[UIImage imageNamed:@"PlaySoundSelected"] forState:UIControlStateHighlighted];
        [self.pcmPlayer playSound];
    }
}

#pragma mark UIPickerView DataSource Method 数据源方法

//指定pickerview有几个表盘
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

//指定每个表盘上有几行数据
-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return self.dateArray.count;
}


#pragma mark - Event Handle
- (void)selectDate{
    self.pickCoverView.hidden = NO;
}

#pragma mark UIPickerView Delegate Method 代理方法

//指定每行如何展示数据（此处和tableview类似）
-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSDate *date = self.dateArray[row];
    return [self getDateStringWithDate:date];
}


//选中时回调的委托方法
-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    self.currentSelectDate = self.dateArray[row];
    [self.dateButton setTitle:[self getDateStringWithDate:self.currentSelectDate] forState:UIControlStateNormal];
    //重新获取数据
    [self getToken];
    [UIView animateWithDuration:0.2 animations:^{
        self.pickCoverView.hidden = YES;
    }];

}

#pragma mark - 播放相关
//- (void)startToDecH264FileWithPort:(NSInteger)port filePath:(NSString *)filePath{
//    _h264FilePath = filePath;
//    [_videoDecoder ac_startDecH264FileWithPort:0 filePath:filePath];
//}
//
//- (void)stopDecH264File{
////    [self saveVideoScreenShot];
//    [_videoDecoder ac_stopDecH264FileWithPort:0];
//    [_videoDecoder ac_uninit];
//}


- (void)saveVideoScreenShot{
    BOOL capResult = [self.videoDecoder ac_captureWithPort:0 filePath: [self snapshotPath]];
    
    if (!capResult)
    {
        [self showNewStatusInfo:DPLocalizedString(@"localizied_9")];
    }
    else
    {
        [self showNewStatusInfo:DPLocalizedString(@"save_image")];
    }

}


- (NSString*)snapshotPath{
    NSString *path = [[MediaManager shareManager] mediaPathWithDevId:[self.deviceId substringFromIndex:8]
                                                           fileName:nil
                                                          mediaType:GosMediaSnapshot
                                                         deviceType:GosDeviceIPC
                                                           position:PositionMain];
    return path;
}

-(void)showNewStatusInfo:(NSString*)info
{
    [SVProgressHUD showInfoWithStatus:info];
    [SVProgressHUD dismissWithDelay:2];
}


#pragma amrk - 屏幕旋转
- (BOOL)shouldAutorotate{
    return NO;
}

#pragma mark - Getter
- (UIButton *)dateButton{
    if (!_dateButton) {
        _dateButton = [[UIButton alloc]initWithFrame:CGRectMake((SCREEN_WIDTH - 120)/2, SCREEN_WIDTH * 9/16 + 120 + 20, 120, 30)];
        _dateButton.backgroundColor = [UIColor whiteColor];
        _dateButton.titleLabel.font = [UIFont systemFontOfSize:15.0f];
        [_dateButton setBackgroundImage:[UIImage imageNamed:@"CloudDateBtnBG"] forState:UIControlStateNormal];
        [_dateButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_dateButton addTarget:self action:@selector(selectDate) forControlEvents:UIControlEventTouchUpInside];
    }
    return _dateButton;

}




- (NSDate *)currentTimeDate{
    return [NSDate dateWithTimeIntervalSinceNow:0];
}



- (NSMutableArray *)cloudPlayUrlArray{
    if (!_cloudPlayUrlArray) {
        _cloudPlayUrlArray = [NSMutableArray array];
    }
    return _cloudPlayUrlArray;
}

- (NSMutableArray *)cloudVideoArray{
    if (!_cloudVideoArray) {
        _cloudVideoArray = [NSMutableArray array];
    }
    return _cloudVideoArray;
}


- (NSMutableArray *)cloudAlarmArray{
    if (!_cloudAlarmArray) {
        _cloudAlarmArray = [NSMutableArray array];
    }
    return _cloudAlarmArray;
}


/**
 *  声音开关 Button
 */
- (UIButton *)soundBtn{
    if (!_soundBtn) {
        _soundBtn = [[UIButton alloc]init];
        [_soundBtn addTarget:self action:@selector(soundBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [_soundBtn setImage:[UIImage imageNamed:@"PlaySoundNormal"] forState:UIControlStateNormal];
        [_soundBtn setImage:[UIImage imageNamed:@"PlaySoundSelected"] forState:UIControlStateHighlighted];
//        _soundBtn.userInteractionEnabled = NO;
    }
    return _soundBtn;
}


/**
 *  剪切 Button
 */
- (UIButton *)shortCutBtn{
    if (!_shortCutBtn) {
        _shortCutBtn = [[UIButton alloc]init];
        [_shortCutBtn setImage:[UIImage imageNamed:@"btn_shear_normal"] forState:UIControlStateNormal];
        [_shortCutBtn setImage:[UIImage imageNamed:@"btn_shear_press"] forState:UIControlStateHighlighted];
        [_shortCutBtn addTarget:self action:@selector(shortCutAction:) forControlEvents:UIControlEventTouchUpInside];
//        _shortCutBtn.userInteractionEnabled = NO;
    }
    return _shortCutBtn;
}


/**
 *  拍照 Button
 */

- (UIButton *)snapshotBtn{
    if (!_snapshotBtn) {
        _snapshotBtn = [[UIButton alloc]init];
        [_snapshotBtn addTarget:self action:@selector(snapshotBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [_snapshotBtn setImage:[UIImage imageNamed:@"PlayCameraNormal"] forState:UIControlStateNormal];
        [_snapshotBtn setImage:[UIImage imageNamed:@"PlayCameraSelected"] forState:UIControlStateHighlighted];
//        _snapshotBtn.userInteractionEnabled = NO;
    }
    return _snapshotBtn;
}


/**
 *  声音开关 Label
 */
- (UILabel *)soundLabel{
    if (!_soundLabel) {
        _soundLabel = [[UILabel alloc]init];
        _soundLabel.font = [UIFont systemFontOfSize:14.0f];
        _soundLabel.textColor = [UIColor colorWithHexString:@"0x242421"];
        _soundLabel.text = DPLocalizedString(@"play_Sound");
        _soundLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _soundLabel;
}


/**
 *  剪切 Label
 */
- (UILabel *)shortCutLabel{
    if (!_shortCutLabel) {
        _shortCutLabel = [[UILabel alloc]init];
        _shortCutLabel.font = [UIFont systemFontOfSize:14.0f];
        _shortCutLabel.textColor = [UIColor colorWithHexString:@"0x242421"];
        _shortCutLabel.text = @"剪切";
        _shortCutLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _shortCutLabel;
}


/**
 *  拍照 Label
 */
- (UILabel *)snapshotLabel{
    if (!_snapshotLabel) {
        _snapshotLabel = [[UILabel alloc]init];
        _snapshotLabel.font = [UIFont systemFontOfSize:14.0f];
        _snapshotLabel.textColor = [UIColor colorWithHexString:@"0x242421"];
        _snapshotLabel.text = DPLocalizedString(@"play_Snapshot");
        _snapshotLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _snapshotLabel;
}

/**
 *  底部 View
 */
- (UIView *)bottomView{
    if (!_bottomView) {
        _bottomView = [[UIView alloc]init];
        _bottomView.backgroundColor = [UIColor whiteColor];
    }
    return _bottomView;
}

/**
 *  顶部View
 */
- (UIView *)topView{
    if (!_topView) {
        _topView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_WIDTH * playViewRatio)];
        _topView.backgroundColor = [UIColor blackColor];
    }
    return _topView;
}

- (UIButton *)previewView{
    if (!_previewView) {
        _previewView = [[UIButton alloc]initWithFrame:CGRectMake(SCREEN_WIDTH/2.0f - 60, playViewRatio * SCREEN_WIDTH - 45 - 64, 120, 90)];
        _previewView.backgroundColor = [UIColor darkGrayColor];
        [_previewView addTarget:self action:@selector(playBtnClick) forControlEvents:UIControlEventTouchUpInside];
        _previewView.userInteractionEnabled = NO;
        _previewView.hidden = YES;
    }
    return _previewView;
}

- (UIImageView *)playButton{
    if (!_playButton) {
        _playButton = [[UIImageView alloc]initWithFrame:CGRectMake(45, 30, 30, 30)];
        _playButton.userInteractionEnabled = NO;
        UIImage *image = [UIImage imageNamed:@"Cloud_btn_play_normal"];
        _playButton.image = image;
//        _playButton.backgroundColor = [UIColor redColor];
        _playButton.hidden = YES;
    }
    return _playButton;
}

- (UIActivityIndicatorView *)loadVideoActivity{
    if (!_loadVideoActivity) {
        _loadVideoActivity = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _loadVideoActivity.frame = CGRectMake(35, 20, 50, 50);
        [_loadVideoActivity startAnimating];
        _loadVideoActivity.hidden = YES;
    }
    return _loadVideoActivity;
}

- (NSMutableArray *)shortCutArray{
    if (!_shortCutArray) {
        _shortCutArray = [NSMutableArray array];
    }
    return _shortCutArray;
}

@end
