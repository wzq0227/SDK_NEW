//
//  AQAudioRecorder.m
//
//  对讲发送G711的时候，先录PCM，本类用来录PCM，然后回调到上层转G711
//
//  Created by Goscam on 2017/10/26.
//  Copyright © 2017年 goscamtest. All rights reserved.
//

#import "AQAudioRecorder.h"
#import "GDVideoStateInfo.h"



#define kNumberAudioQueueBuffers 3  //定义了三个缓冲区
#define kDefaultBufferDurationSeconds 0.1279   //调整这个值使得录音的缓冲区大小为2048bytes
#define kDefaultSampleRate 8000   //定义采样率为8000

@interface AQAudioRecorder(){
    //音频输入队列
    AudioQueueRef _audioQueue;
    //音频输入数据format
    AudioStreamBasicDescription _recordFormat;
    
    //音频输入缓冲区
    AudioQueueBufferRef _audioBuffers[kNumberAudioQueueBuffers];
}


@property (nonatomic, assign) BOOL isRecording;

@property (atomic, assign) int sampleRate;
@property (atomic, assign) double bufferDurationSeconds;

@property (strong, nonatomic)  AQAudioCallback audioCallbackBlock;

@end


@implementation AQAudioRecorder

- (void)configModel{
    _sampleRate = kDefaultSampleRate;
    _bufferDurationSeconds = kDefaultBufferDurationSeconds;
    
    //设置录音的format数据
    [self setupAudioFormat:kAudioFormatLinearPCM SampleRate:_sampleRate];
}

// 设置录音格式
- (void)setupAudioFormat:(UInt32) inFormatID SampleRate:(int)sampeleRate
{
    //重置下
    memset(&_recordFormat, 0, sizeof(_recordFormat));
    
    //设置采样率，这里先获取系统默认的测试下 //TODO:
    //采样率的意思是每秒需要采集的帧数
    _recordFormat.mSampleRate = sampeleRate;
    
    //设置通道数,这里先使用系统的测试下 //TODO:
    _recordFormat.mChannelsPerFrame = 1;
    
    //    NSLog(@"sampleRate:%f,通道数:%d",_recordFormat.mSampleRate,_recordFormat.mChannelsPerFrame);
    
    //设置format，怎么称呼不知道。
    _recordFormat.mFormatID = inFormatID;
    
    if (inFormatID == kAudioFormatLinearPCM){
        //这个屌属性不知道干啥的。，//要看看是不是这里属性设置问题
        _recordFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
        //每个通道里，一帧采集的bit数目
        _recordFormat.mBitsPerChannel = 16;
        //结果分析: 8bit为1byte，即为1个通道里1帧需要采集2byte数据，再*通道数，即为所有通道采集的byte数目。
        //所以这里结果赋值给每帧需要采集的byte数目，然后这里的packet也等于一帧的数据。
        //至于为什么要这样。。。不知道。。。
        _recordFormat.mBytesPerPacket = _recordFormat.mBytesPerFrame = (_recordFormat.mBitsPerChannel / 8) * _recordFormat.mChannelsPerFrame;
        _recordFormat.mFramesPerPacket = 1;
    }
}


-(void)startRecordingWithAudioCallback:(AQAudioCallback)callback
{
    NSLog(@"-----------------开启对讲录声音------------");
    self.isRecording = YES;

    [self configModel];
    
    self.audioCallbackBlock = callback;
    
//    NSError *error = nil;
//    //设置audio session的category
//    BOOL ret = [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryRecord error:&error];//注意，这里选的是AVAudioSessionCategoryPlayAndRecord参数，如果只需要录音，就选择Record就可以了，如果需要录音和播放，则选择PlayAndRecord，这个很重要
//    if (!ret) {
//        NSLog(@"设置声音环境失败");
//        return;
//    }
//    //启用audio session
//    ret = [[AVAudioSession sharedInstance] setActive:YES error:&error];
//    if (!ret)
//    {
//        NSLog(@"启动失败");
//        return;
//    }
    
    _recordFormat.mSampleRate = self.sampleRate;//设置采样率，8000hz
    
    /**
     初始化音频输入队列 这里传入的self 会在inputBufferHandler的inUserData这个参数里面回调回来,
     从而可以再次调用本类里面的方法
    */
    AudioQueueNewInput(&_recordFormat, inputBufferHandler, (__bridge void *)(self), NULL, NULL, 0, &_audioQueue);
    
    
    //计算估算的缓存区大小
    int frames = (int)ceil(self.bufferDurationSeconds * _recordFormat.mSampleRate);//返回大于或者等于指定表达式的最小整数
    int bufferByteSize = frames * _recordFormat.mBytesPerFrame;//缓冲区大小在这里设置，这个很重要，在这里设置的缓冲区有多大，那么在回调函数的时候得到的inbuffer的大小就是多大。
    NSLog(@"缓冲区大小:%d",bufferByteSize);
    
    //创建缓冲器
    for (int i = 0; i < kNumberAudioQueueBuffers; i++){
        AudioQueueAllocateBuffer(_audioQueue, bufferByteSize, &_audioBuffers[i]);
        AudioQueueEnqueueBuffer(_audioQueue, _audioBuffers[i], 0, NULL);//将 _audioBuffers[i]添加到队列中
    }
    
    // 开始录音
    AudioQueueStart(_audioQueue, NULL);
    [self removeExistingFile];
}

- (void)removeExistingFile{
    NSString *g711FilePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent: @"interfacetalk_tmp.711"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:g711FilePath ]) {
        [[NSFileManager defaultManager] removeItemAtPath:g711FilePath error:nil];
    }
}



//相当于中断服务函数，每次录取到音频数据就进入这个函数
//inAQ 是调用回调函数的音频队列
//inBuffer 是一个被音频队列填充新的音频数据的音频队列缓冲区，它包含了回调函数写入文件所需要的新数据
//inStartTime 是缓冲区中的一采样的参考时间，对于基本的录制，你的回调函数不会使用这个参数
//inNumPackets是inPacketDescs参数中包描述符（packet descriptions）的数量，如果你正在录制一个VBR(可变比特率（variable bitrate））格式, 音频队列将会提供这个参数给你的回调函数，这个参数可以让你传递给AudioFileWritePackets函数. CBR (常量比特率（constant bitrate）) 格式不使用包描述符。对于CBR录制，音频队列会设置这个参数并且将inPacketDescs这个参数设置为NULL，官方解释为The number of packets of audio data sent to the callback in the inBuffer parameter.

void inputBufferHandler(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer, const AudioTimeStamp *inStartTime,UInt32 inNumPackets, const AudioStreamPacketDescription *inPacketDesc)
{
//    NSLog(@"we are in the 回调函数\n");
    AQAudioRecorder *recorder = (__bridge AQAudioRecorder*)inUserData;
    
    if (inNumPackets > 0 && [recorder isKindOfClass:[AQAudioRecorder class] ] && recorder.isRecording) {
        [recorder processAudioBuffer:inBuffer withQueue:inAQ];    //在这个函数你可以用录音录到得PCM数据：inBuffer，去进行处理了
    }
    
    if (recorder.isRecording) {
        AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL);
    }
}

-(void)processAudioBuffer:(AudioQueueBufferRef)audioBuffer withQueue:(AudioQueueRef)audioQueue{
    
    NSData *pcmData = [[NSData alloc]initWithBytes:audioBuffer->mAudioData length:audioBuffer->mAudioDataByteSize];
    if (pcmData.length>0) {
        
        if (self.audioCallbackBlock && self.isRecording) {
            self.audioCallbackBlock(pcmData);
        }
        NSLog(@"processAudioBuffer_____pcmData: %d",(int)pcmData.length);
    }
}


-(void)stopRecordingWithResult:(RecordingResult)result
{
    NSLog(@"stop recording out\n");//为什么没有显示
    if (self.isRecording)
    {
        self.isRecording = NO;

//        usleep(100);
        OSStatus status = AudioQueueFlush(_audioQueue);

        NSLog(@"AudioQueueFlush________status:%d",(int)status);
        
        //停止录音队列和移除缓冲区,以及关闭session，这里无需考虑成功与否
        status = AudioQueueStop(_audioQueue, true);
        NSLog(@"AudioQueueStop________status:%d",(int)status);

        status = AudioQueueDispose(_audioQueue, true);//移除缓冲区,true代表立即结束录制，false代表将缓冲区处理完再结束
//        [[AVAudioSession sharedInstance] setActive:NO error:nil];
        
        NSLog(@"AudioQueueDispose________status:%d",(int)status);

        result(0);

    }else{
        result(-1);
    }
}

@end
