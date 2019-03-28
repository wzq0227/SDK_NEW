//
//  GOSOpenGLESVCViewController.m
//  360
//
//  Created by zhuochuncai on 18/7/17.
//  Copyright © 2017年 Gospell. All rights reserved.
//

#import "GOSOpenGLESVCViewController.h"

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#include <math.h>

#import "ACVideoDecoder.h"
#import "Masonry.h"
#import "GDDeviceIcon.h"
#import "KKSimpleAUPlayer.h"

#define PlayerViewRatio (iPhone4 ? (3/4.0f):(65/72.0f))


@interface GOSOpenGLESVCViewController ()<GLKViewDelegate,UIGestureRecognizerDelegate>
{
    int m_touchStatus,  m_tx, m_ty,  m_clickSig;
    BOOL m_rot;
    BOOL m_is3d;
    
    BOOL m_disOld;
    float zoomSig[4] ;
    
    CGFloat lastScale;
    CGPoint lastPoint;
}


@property(nonatomic,strong)EAGLContext *eagContext;
@property(nonatomic,strong)UIView *topBgView;
@property(nonatomic,strong)NSMutableArray *buttonsArray;


/**
 屏幕像素实际的缩放因子，排除Plus设备计算不准的情况
 */
@property(nonatomic,assign)CGFloat mScreenScale;
/**
 音频播放
 */
@property(nonatomic,strong)KKSimpleAUPlayer *audioPlayer;

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
@property(nonatomic,strong)ACVideoDecoder *videoDecoder;

@property (strong, nonatomic)  GOSAudioRecorder *audioRecorder;

@property(nonatomic,strong)NSLock *lock;

@property(nonatomic,strong)NSLock *bufferQueueLock;

@property(nonatomic,strong)RecordCallbackBlock recordBlock;
@end

static GOSOpenGLESVCViewController *aSelf;

@implementation GOSOpenGLESVCViewController


- (id)init{
    self = [super init];
    if (self) {
        self.bufferQueue = [NSMutableArray arrayWithCapacity:1];
        self.lock = [[NSLock alloc] init];
        self.bufferQueueLock = [[NSLock alloc] init];
        self.audioRecorder = [[GOSAudioRecorder alloc] init];
        self.autoRotSig = 1;
        self.clickSig = -1;
        [self initDecoder];
        aSelf = self;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self addGestures];
//    [self setupContext];

}

- (void)dealloc{
    NSLog(@"gosOpenGLES_Dealloc");
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    //    [self tearDownGL];
    if ([EAGLContext currentContext] == _eagContext) {
        [EAGLContext setCurrentContext:nil];
    }
    _eagContext = nil;
}

- (void)initDecoder{
    _videoDecoder = [[ACVideoDecoder alloc] init];
    [_videoDecoder initVideoDecoderWithDataCallBack:^(PDecodedFrameParam frameParam) {
        if (!frameParam) {//重新开始解码264
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self startToDecH264FileWithPort:0 filePath:_h264FilePath];
            });
            return ;
        }
        if ( frameParam->lpBuf == NULL)
        {
            return;
        }
//        NSLog(@"VideoDecoderCallBack___________________width:%ld height:%ld size:%ld",frameParam->lWidth,frameParam->lHeight,frameParam->lSize);
        if ( frameParam->nDecType == 0 ) {//YUV
            
            @autoreleasepool {
                
                long imageSize = frameParam->lWidth * frameParam->lHeight*3/2;
                
                if ( frameParam->lWidth!=0 && _videoWidth != frameParam->lWidth) {
                    _videoWidth = frameParam->lWidth;
                    _videoHeight = frameParam->lHeight;

                    [_bufferQueueLock lock];
                    [self.bufferQueue removeAllObjects];
                    [_bufferQueueLock unlock];
                    
                    [self setupContext];
                    [_player gosPanorama_updateVideoWidth:_videoWidth height:_videoHeight];
                }
                
                NSData *yuvData = [NSData dataWithBytes:frameParam->lpBuf length: imageSize];
                
                [_bufferQueueLock lock];
                [self.bufferQueue addObject: yuvData];
                [_bufferQueueLock unlock];
            }
        }
    }];
}

- (void)startToDecH264FileWithPort:(NSInteger)port filePath:(NSString *)filePath{
    _h264FilePath = filePath;
    [_videoDecoder ac_startDecH264FileWithPort:0 isRandom:1 filePath:filePath];
}

- (void)stopDecH264File{
    [self saveVideoScreenShot];
    [_videoDecoder ac_stopDecH264FileWithPort:0];
    [_videoDecoder ac_uninit];
}

- (void)saveVideoScreenShot{
    NSString *screenShotImgName = @"ExpCenter_VR_180";
    if (_initialMode == InitialModeVertical) {
        screenShotImgName = @"ExpCenter_VR_180";
    }else{
        screenShotImgName = @"ExpCenter_VR_360";
    }
    
    NSString *screenShotFilePath = [mDocumentPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg",screenShotImgName]];
    BOOL capResult = [_videoDecoder ac_captureWithPort:0 filePath: screenShotFilePath];
    NSLog(@"ExpCenter_VR_360________________saveVideoScreenShotSucceeded:%d",capResult);
}

- (void)startRecordingWithStoragePath:(NSString*)filePath result:(RecordCallbackBlock)block{
    
    _recordBlock = block;
    BOOL result = [_videoDecoder ac_startRecordWithPort:0 filePath:self.recordPath audioType:0 callBack:recordCallBackFunc];
    NSLog(@"startRecording_ret:%d",result);
    if(block){
        block(result?0:-1,0);
    }
}

- (void)stopRecording{
    [_videoDecoder ac_stopRecord];
}


static long  recordCallBackFunc( AVRecordEvent eventRec, long lData)
{
    // 根据 eventRec 做对应处理
    // 返回录像状态，当前录像时长、播放时长
    
    if (aSelf.recordBlock) {
        
        if (eventRec == AVRecordEventRetTime) {
            aSelf.recordBlock(1,lData);
        }else if (eventRec == AVRecordEventOpenSuccess){
            aSelf.recordBlock(0,0);
        }else if (eventRec == AVRecordEventOpenErr){
            aSelf.recordBlock(-1,lData);
        }else if (eventRec == AVRecordEventTimeEnd){
            aSelf.recordBlock(-1,lData);
        }
    }
    
    
    NSLog(@"RecordCallBackFunc______%d lData:%d ",eventRec, lData);
    return 1;
}

//截屏两种:一种用户手动截屏，存储到设置里面的相册 另一种用于刷新列表界面的每个设备
- (void)snapshotWithStoragePath:(NSString*)filePath result:(SnapshotResultBlock)block{
    
    long capResult =  [_videoDecoder ac_captureWithPort:0 filePath:self.snapshotPath];
    
    if ( capResult ) {
        
        NSLog(@"updateScreenshotData_Capture_succeeded");
        // 发送更新封面通知
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateScrrenShot"
                                                            object:nil];
    }else{
        NSLog(@"updateScreenshotData_Capture_failed");
    }
    block(capResult?0:-1);
}

//接收数据，传入ACVideoDecoder，解码之后传给
-(void)AddVideoFrame:(unsigned char *)pContentBuffer
                 len:(int)len
                  ts:(int)ts
              framNo:(unsigned int)framNO
           frameRate:(int)frameRate
              iFrame:(BOOL) iFrame
        andDeviceUid:(NSString *)UID
{
    if (_videoDecoder) {
        [_lock lock];
        [_videoDecoder ac_putFrameWithPort:0 Buffer:pContentBuffer length:len];
        [_lock unlock];
    }
    
}

/**
 开启对讲并开始录音
 */
- (void)startAudioRecording{
    [_audioRecorder gos_startAudioRecorderResultCallback:^(int result, NSString *filePath) {
        //
    }];
}


/**
 停止录音并发送对讲
 */
-(void)stopAudioRecording{
    
    __weak typeof(self) weakSelf = self;
    [_audioRecorder gos_stopAudioRecorderResultCallback:^(int result, NSString *filePath) {
        {
            if ([weakSelf.audioDelegate respondsToSelector:@selector(SendVoiceRecoderData:andFilePath:)]) {
                [weakSelf.audioDelegate SendVoiceRecoderData:result==0 andFilePath: filePath];
            }
        }
    } ];
}

/**
 开启实时音频
 */
- (void)openLiveAudio{
    if (_audioPlayer == nil) {
        _audioPlayer = [[KKSimpleAUPlayer alloc]init];
        [_audioPlayer play];
    }
}


/**
 关闭实时音频
 */
- (void)closeLiveAudio{
    if (_audioPlayer != nil) {
        [_audioPlayer pause];
        
        _audioPlayer = nil;
    }
}

#pragma mark -- 将从网络获取的音频数据丢给音频播放器播放
-(void)AddAudioFrame:(Byte *)buffer
                 len:(int)len
              framNo:(unsigned int)framNO
            isIframe:(bool)iFrame
           timeStamp:(unsigned long long)ts
{
    
    [_videoDecoder ac_putFrameWithPort:0 Buffer:buffer length:len];
    [self.audioPlayer playWith:(char*)buffer andBufferLen:len];
}

- (NSString*)coverPath{
    
    if (!_coverPath) {
        _coverPath = [[MediaManager shareManager] mediaPathWithDevId:self.deviceId
                                                        fileName:nil
                                                       mediaType:GosMediaCover
                                                      deviceType:GosDevice360
                                                        position:PositionMain];
    }
    return _coverPath;
}

- (NSString*)snapshotPath{


    _snapshotPath = [[MediaManager shareManager] mediaPathWithDevId:self.deviceId
                                                           fileName:nil
                                                          mediaType:GosMediaSnapshot
                                                         deviceType:GosDevice360
                                                           position:PositionMain];
    return _snapshotPath;
}

- (NSString*)recordPath{
    _recordPath = [[MediaManager shareManager] mediaPathWithDevId:self.deviceId
                                                            fileName:nil
                                                           mediaType:GosMediaRecord
                                                          deviceType:GosDevice360
                                                            position:PositionMain];
    return _recordPath;
}


- (void)stopPlay{
    
    BOOL capResult = [_videoDecoder ac_captureWithPort:0 filePath: self.coverPath];
    if ( capResult ) {
        NSLog(@"updateScreenshotData_Capture_succeeded");
        // 发送更新封面通知
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateScrrenShot"
                                                            object:nil];
    }
    [_videoDecoder ac_uninit];
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    [super touchesBegan:touches withEvent:event];
    
    NSSet<UITouch*>*mTouches = [event touchesForView:self.view];
    
    //touchesForView event.allTouches
    if (mTouches.count==1) {//Pan
        UITouch *touch = [mTouches allObjects][0];
        CGPoint gesPosition = [touch locationInView:self.view];
        
        _player.tx = gesPosition.x*_mScreenScale;
        _player.ty = gesPosition.y*_mScreenScale;
        
        if (touch.phase == UITouchPhaseBegan) {
            _player.touchStatus = 0;
        }
        
        if (touch.phase == UITouchPhaseMoved ) {
            _player.touchStatus = 1;
        }
        
        if (touch.phase == UITouchPhaseEnded) {
            _player.touchStatus = 2;
        }
    }else if (mTouches.count == 2){//Pinch
        UITouch *touch0 = [mTouches allObjects][0];
        UITouch *touch1 = [mTouches allObjects][1];
        
        CGPoint pos0 = [touch0 locationInView:self.view];
        CGPoint pos1 = [touch1 locationInView:self.view];
        
        
        CGFloat changedW = (pos1.x - pos0.x)*_mScreenScale;
        CGFloat changedH = (pos1.y - pos0.y)*_mScreenScale;
        
        if (touch1.phase == UITouchPhaseBegan || touch0.phase == UITouchPhaseBegan) {
            _player.touchStatus = 3;
            _player.zoomSig1 = _player.zoomSig2 = 0;
            _player.zoomSig0 = sqrtf(changedW*changedW + changedH*changedH);
            if (_player.zoomSig0 < 1) {
                NSLog(@"ges_error");
            }
        }
        
        if (touch1.phase == UITouchPhaseMoved || touch0.phase == UITouchPhaseMoved) {
            _player.touchStatus = 4;
            _player.zoomSig1 = sqrtf(changedW*changedW + changedH*changedH);
            _player.zoomSig2 = _player.zoomSig1 - _player.zoomSig0;
        }
        
        if (touch1.phase == UITouchPhaseEnded || touch0.phase == UITouchPhaseEnded) {
            _player.touchStatus = 5;
        }
        //NSLog(@"zoomSig[3]: %4.2f   %4.2f  %4.2f  phase = %d",_player.zoomSig0, _player.zoomSig1, _player.zoomSig2, touch0.phase);
    }
    [self.view setNeedsDisplay];
    [_player gosPanorama_updateMotionSignal];

   // NSLog(@"touchesBegan___________count:%d  mTouchCount:%d",touches.count,mTouches.count);
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    [super touchesMoved:touches withEvent:event];

    NSSet<UITouch*>*mTouches = [event touchesForView:self.view];

    if (mTouches.count==1) {//Pan
        UITouch *touch = [mTouches allObjects][0];
        CGPoint gesPosition = [touch locationInView:self.view];
        
        _player.tx = gesPosition.x*_mScreenScale;
        _player.ty = gesPosition.y*_mScreenScale;
        
        if (touch.phase == UITouchPhaseBegan) {
            _player.touchStatus = 0;
        }
        
        if (touch.phase == UITouchPhaseMoved ) {
            _player.touchStatus = 1;
        }
        
        if (touch.phase == UITouchPhaseEnded) {
            _player.touchStatus = 2;
        }
    }else if (mTouches.count == 2){//Pinch
        UITouch *touch0 = [mTouches allObjects][0];
        UITouch *touch1 = [mTouches allObjects][1];
        
        CGPoint pos0 = [touch0 locationInView:self.view];
        CGPoint pos1 = [touch1 locationInView:self.view];
        
        
        CGFloat changedW = (pos1.x - pos0.x)*_mScreenScale;
        CGFloat changedH = (pos1.y - pos0.y)*_mScreenScale;
        
        if (touch1.phase == UITouchPhaseBegan || touch0.phase == UITouchPhaseBegan) {
            _player.touchStatus = 3;
            _player.zoomSig1 = _player.zoomSig2 = 0;
            _player.zoomSig0 = sqrtf(changedW*changedW + changedH*changedH);
            if (_player.zoomSig0 < 1) {
                NSLog(@"ges_error");
            }
        }
        
        if (touch1.phase == UITouchPhaseMoved || touch0.phase == UITouchPhaseMoved) {
            _player.touchStatus = 4;
            _player.zoomSig1 = sqrtf(changedW*changedW + changedH*changedH);
            _player.zoomSig2 = _player.zoomSig1 - _player.zoomSig0;
        }
        
        if (touch1.phase == UITouchPhaseEnded || touch0.phase == UITouchPhaseEnded) {
            _player.touchStatus = 5;
        }
        //NSLog(@"zoomSig[3]: %4.2f   %4.2f  %4.2f  phase = %d",_player.zoomSig0, _player.zoomSig1, _player.zoomSig2, touch0.phase);
    }
    [self.view setNeedsDisplay];
    [_player gosPanorama_updateMotionSignal];

   // NSLog(@"touchesMoved___________count:%d  mTouchCount:%d",touches.count,mTouches.count);
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    [super touchesEnded:touches withEvent:event];

    NSSet<UITouch*>*mTouches = [event touchesForView:self.view];

    if (mTouches.count==1) {//Pan
        UITouch *touch = [mTouches allObjects][0];
        CGPoint gesPosition = [touch locationInView:self.view];
        
        _player.tx = gesPosition.x*_mScreenScale;
        _player.ty = gesPosition.y*_mScreenScale;
        
        if (touch.phase == UITouchPhaseBegan) {
            _player.touchStatus = 0;
        }
        
        if (touch.phase == UITouchPhaseMoved ) {
            _player.touchStatus = 1;
        }
        
        if (touch.phase == UITouchPhaseEnded) {
            _player.touchStatus = 2;
        }
    }else if (mTouches.count == 2){//Pinch
        UITouch *touch0 = [mTouches allObjects][0];
        UITouch *touch1 = [mTouches allObjects][1];
        
        CGPoint pos0 = [touch0 locationInView:self.view];
        CGPoint pos1 = [touch1 locationInView:self.view];
        
        
        CGFloat changedW = (pos1.x - pos0.x)*_mScreenScale;
        CGFloat changedH = (pos1.y - pos0.y)*_mScreenScale;
        
        if (touch1.phase == UITouchPhaseBegan || touch0.phase == UITouchPhaseBegan) {
            _player.touchStatus = 3;
            _player.zoomSig1 = _player.zoomSig2 = 0;
            _player.zoomSig0 = sqrtf(changedW*changedW + changedH*changedH);
            if (_player.zoomSig0 < 1) {
                NSLog(@"ges_error");
            }
        }
        
        if (touch1.phase == UITouchPhaseMoved || touch0.phase == UITouchPhaseMoved) {
            _player.touchStatus = 4;
            _player.zoomSig1 = sqrtf(changedW*changedW + changedH*changedH);
            _player.zoomSig2 = _player.zoomSig1 - _player.zoomSig0;
        }
        
        if (touch1.phase == UITouchPhaseEnded || touch0.phase == UITouchPhaseEnded) {
            _player.touchStatus = 5;
        }
        //NSLog(@"zoomSig[3]: %4.2f   %4.2f  %4.2f  phase = %d",_player.zoomSig0, _player.zoomSig1, _player.zoomSig2, touch0.phase);
    }
    [self.view setNeedsDisplay];
    [_player gosPanorama_updateMotionSignal];

   // NSLog(@"touchesEnded___________count:%d  mTouchCount:%d",touches.count,mTouches.count);
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event{
    
    [super touchesCancelled:touches withEvent:event];
    
    [self.view setNeedsDisplay];
   // NSLog(@"touchesCancelled___________________");
}

- (void)addGestures{
    [self addTapGesture];
//    [self addPanGesture];
}

- (void)addTapGesture{
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureAction:)];
    gesture.numberOfTapsRequired = 2;
    gesture.delegate = self;
    [self.view addGestureRecognizer:gesture];
}

- (void)tapGestureAction:(UITapGestureRecognizer*)gesture{
    
    _player.touchStatus=0;
    CGPoint gesPosition = [gesture locationInView:self.view];
    _player.tx = gesPosition.x*_mScreenScale;
    _player.ty = gesPosition.y*_mScreenScale;
    
    if (_player.clickDouble == 0) {
        _player.clickDouble = 1;
    }else{
        _player.clickDouble = 0;
    }
    [_player gosPanorama_updateMotionSignal];
}

//- (void)panGestureAction:(UIPanGestureRecognizer*)gesture{
//    
//    CGPoint gesPosition = [gesture locationInView:self.view];
//    
//    _player.tx = gesPosition.x*_mScreenScale;
//    _player.ty = gesPosition.y*_mScreenScale;
//    if (gesture.state == UIGestureRecognizerStateEnded) {
//        _player.touchStatus = 2;
//        return;
//    }
//    if (gesture.state == UIGestureRecognizerStateBegan) {
//        _player.touchStatus = 0;
//        return;
//    }
//    _player.touchStatus = 1;
//}
//
////拖动
//- (void)addPanGesture{
//    UIPanGestureRecognizer *gesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureAction:)];
//    gesture.delegate = self;
//    [self.view addGestureRecognizer:gesture];
//}
//
//
//两个手指缩放





//1920:1080
- (void)setupContext{
    
    _mScreenScale = SCREEN_SCALE;
    if( _mScreenScale > 2.1 ){
        _mScreenScale = 1080.0/414;
    }
    if (self.eagContext) {
        self.eagContext = nil;
        [EAGLContext setCurrentContext:nil];
    }
    
    self.eagContext = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    GLKView *view = (GLKView*)self.view;
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;//GLKViewDrawableDepthFormat24;
    view.drawableStencilFormat = GLKViewDrawableStencilFormat8;
    view.context = self.eagContext;
    
    //    view.drawableMultisample = GLKViewDrawableMultisample4X;
    //    view.delegate = self; GLKVC自动添加这行代码
    [EAGLContext setCurrentContext:self.eagContext];
    
    
    self.preferredFramesPerSecond = _videoHeight==1080?25:20;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.view.multipleTouchEnabled = YES;
    });

    self.view.backgroundColor = [UIColor clearColor];

    _displayWidth  = self.view.width* _mScreenScale;
    _displayHeight = self.view.height*_mScreenScale;
    
    if (!_player) {
        _player = [[GOSPanoramaPlayer alloc] initWithFrame:self.view.bounds];
        _player.delegateView = view;
        
    }
    _player.autoRotSig = self.autoRotSig;
    _player.clickSig = self.clickSig;
    [_player gosPanorama_initWithWidth:_videoWidth height: _videoHeight  disWidth:_displayWidth disHeight:_displayHeight initialMode:_initialMode];
}


//在[PanoramaLiveVC.playerView addSubview:GosOpenGLESVC.view]之前调用本方法设置context的话，由于此时GosOpenGLESVC.view还没有加载(ViewDidLoad没有调用)，view为空，所以调用并且设置context无效
// 故要放在viewDidLoad之后
- (void)configPlayerWidth:(CGFloat)width height:(CGFloat)height{
    
    _displayWidth = width;
    _displayHeight = height;
}

- (void)updatePlayerViewFrame:(CGRect)frame{
//    int scale = [UIScreen mainScreen].scale;

    _displayWidth = frame.size.width*_mScreenScale;
    _displayHeight = frame.size.height*_mScreenScale;
    [_player gosPanorama_updateDisplayWidth:_displayWidth height:_displayHeight];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    NSLog(@"didReceiveMemoryWarning");
    // Dispose of any resources that can be recreated.
}

//0 : 0 : 0 : -1 : 0 : 0.0 : 0.0 : 0.0 : 0
//[((GLKView *) self.view) bindDrawable];


-(void)glkView:(GLKView *)view drawInRect:(CGRect)rect{

    if (self.bufferQueue.count>0) {
        
//        UInt8 *pBuf = malloc(self.bufferQueue[0].length);
//        memcpy(pBuf, self.bufferQueue[0].bytes, self.bufferQueue[0].length);

        [_bufferQueueLock lock];
        [_player gosPanorama_updateWithYUVData: (UInt8*)self.bufferQueue[0].bytes ];
        [_bufferQueueLock unlock];

        [_bufferQueueLock lock];
        [self.bufferQueue removeObjectAtIndex:0];
        [_bufferQueueLock unlock];
    }else{
        [_player gosPanorama_updateWithYUVData: nil ];
    }
    

//    [_player gosPanorama_stepWithTouchStatus:0 tx:0 ty:0 clickSig:-1 autoRotSignal:0 zoomSig0:0.0 zoomSig1:0.0 zoomSig2:0.0 disold:0 clickDouble:0];
}


@end
