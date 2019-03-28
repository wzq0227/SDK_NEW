//
//  PCMPlayer.m
//  GDVideoPlayer
//
//  Created by zhuochuncai on 12/1/17.
//  Copyright © 2017年 goscamtest. All rights reserved.
//

#import "PCMPlayer.h"

@interface PCMPlayer ()

@end

@implementation PCMPlayer

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



-(BOOL)initOpenAL
{
    if (m_Device ==nil)
    {
        m_Device = alcOpenDevice(NULL);                      //参数为NULL , 让ALC 使用默认设备
    }
    
    if (m_Device==nil)
    {
        return NO;
    }
    if (m_Context==nil)
    {
        if (m_Device)
        {
            m_Context =alcCreateContext(m_Device, NULL);      //与初始化device是同样的道理
            alcMakeContextCurrent(m_Context);
        }
    }
    
    alGenSources(1, &m_sourceID);                                                           //初始化音源ID
    alSourcei(m_sourceID, AL_LOOPING, AL_FALSE);                         // 设置音频播放是否为循环播放，AL_FALSE是不循环
    alSourcef(m_sourceID, AL_SOURCE_TYPE, AL_STREAMING);  // 设置声音数据为流试，（openAL 针对PCM格式数据流）
    alSourcef(m_sourceID, AL_GAIN, 1.0f);                                               //设置音量大小，1.0f表示最大音量。openAL动态调节音量大小就用这个方法
    //    alDopplerVelocity(1.0);                                                                         //多普勒效应，这属于高级范畴，不是做游戏开发，对音质没有苛刻要求的话，一般无需设置
    //    alDopplerFactor(1.0);                                                                            //同上
    alSpeedOfSound(1.0);                                                                            //设置声音的播放速度
    
    m_DecodeLock =[[NSCondition alloc] init];
    if (m_Context==nil)
    {
        return NO;
    }

    return YES;
}


//清楚已存在的buffer，这个函数其实没什么的，就只是用来清空缓存而已，我只是多一步将播放声音放到这个函数里。
-(BOOL)updateQueueBuffer
{
    ALint  state;
    int processed ,queued;
    
    alGetSourcei(m_sourceID, AL_SOURCE_STATE, &state);
    if (state !=AL_PLAYING)
    {
        [self playSound];
        return NO;
    }
    
    alGetSourcei(m_sourceID, AL_BUFFERS_PROCESSED, &processed);
    alGetSourcei(m_sourceID, AL_BUFFERS_QUEUED, &queued);
    
    
//    NSLog(@"Processed = %d\n", processed);
//    NSLog(@"Queued = %d\n", queued);
    while (processed--)
    {
        ALuint  buffer;
        alSourceUnqueueBuffers(m_sourceID, 1, &buffer);
        alDeleteBuffers(1, &buffer);
    }
    return YES;
}

//这个函数就是比较重要的函数了， 将收到的pcm数据放到缓存器中，再拿出来播放
- (void)openAudioWithBuffer:(unsigned char *)pBuffer length:(int)pLength
{
    
    [m_DecodeLock lock];
    
    ALenum  error =AL_NO_ERROR;
    if ((error =alGetError())!=AL_NO_ERROR)
    {
        [m_DecodeLock unlock];
        return ;
    }
    if (pBuffer ==NULL)
    {
        return ;
    }
    
    [self updateQueueBuffer];                                  //在这里调用了刚才说的清除缓存buffer函数，也附加声音播放
    
    if ((error =alGetError())!=AL_NO_ERROR)
    {
        NSLog(@"alGetError____________:%x",error);
        [m_DecodeLock unlock];
//        return ;
    }
    
    ALuint    bufferID =0;                                             //存储声音数据，建立一个pcm数据存储器，初始化一块区域用来保存声音数据
    alGenBuffers(1, &bufferID);
    
    if ((error = alGetError())!=AL_NO_ERROR)
    {
        NSLog(@"Create buffer failed");
        [m_DecodeLock unlock];
        return;
    }
    
    NSData  *data =[NSData dataWithBytes:pBuffer length:pLength];                                                                    //将PCM格式数据转换成NSData ,
    alBufferData(bufferID, AL_FORMAT_MONO16, (char *)[data bytes] , (ALsizei)[data length], 8000 );         //将转好的NSData存放到之前初始化好的一块buffer区域中并设置好相应的播放格式 ，（本人使用的播放格式: 单声道16bit(AL_FORMAT_MONO16) , 采样率 8000HZ）
    
    if ((error =alGetError())!=AL_NO_ERROR)
    {
        NSLog(@"create bufferData failed");
        [m_DecodeLock unlock];
        return;
    }
    
    //添加到缓冲区
    alSourceQueueBuffers(m_sourceID, 1, &bufferID);
    
    if ((error =alGetError())!=AL_NO_ERROR)
    {
        NSLog(@"add buffer to queue failed");
        [m_DecodeLock unlock];
        return;
    }
    if ((error=alGetError())!=AL_NO_ERROR)
    {
        NSLog(@"play failed");
        alDeleteBuffers(1, &bufferID);
        [m_DecodeLock unlock];
        return;
    }
    
    [m_DecodeLock unlock];
    
}
-(void)playSound
{
    ALint  state;
    alGetSourcei(m_sourceID, AL_SOURCE_STATE, &state);
    if (state != AL_PLAYING)
    {
        alSourcePlay(m_sourceID);
    }
}

-(void)stopSound
{
    ALint  state;
    alGetSourcei(m_sourceID, AL_SOURCE_STATE, &state);
    if (state != AL_STOPPED)
    {
        
        alSourceStop(m_sourceID);
    }
}

-(void)clearOpenAL
{
    alDeleteSources(1, &m_sourceID);
    if (m_Context != nil)
    {
        alcDestroyContext(m_Context);
        m_Context=nil;
    }
    if (m_Device !=nil)
    {
        alcCloseDevice(m_Device);
        m_Device=nil;
    }
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
