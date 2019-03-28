//
//  KKSimpleAUnitPlayer.m
//  audioplay
//
//  Created by goscam on 16/4/8.
//  Copyright © 2016年 goscam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KKSimpleAUPlayer.h"
#import "GDVideoStateInfo.h"
#import <AVFoundation/AVFoundation.h>
#import "gos-processing.h"

//static void sessionPropertyListener(void *                  inClientData,
//                                    AudioSessionPropertyID  inID,
//                                    UInt32                  inDataSize,
//                                    const void *            inData);


static BOOL checkError(OSStatus error, const char *operation);
static float g_mSampleRate;
static void KKAudioFileStreamPropertyListener(void* inClientData,
                                              AudioFileStreamID inAudioFileStream,
                                              AudioFileStreamPropertyID inPropertyID,
                                              UInt32* ioFlags);
static void KKAudioFileStreamPacketsCallback(void* inClientData,
                                             UInt32 inNumberBytes,
                                             UInt32 inNumberPackets,
                                             const void* inInputData,
                                             AudioStreamPacketDescription *inPacketDescriptions);
static OSStatus KKPlayerAURenderCallback(void *userData,
                                         AudioUnitRenderActionFlags *ioActionFlags,
                                         const AudioTimeStamp *inTimeStamp,
                                         UInt32 inBusNumber,
                                         UInt32 inNumberFrames,
                                         AudioBufferList *ioData);
static OSStatus KKPlayerConverterFiller(AudioConverterRef inAudioConverter,
                                        UInt32* ioNumberDataPackets,
                                        AudioBufferList* ioData,
                                        AudioStreamPacketDescription** outDataPacketDescription,
                                        void* inUserData);

static const OSStatus KKAudioConverterCallbackErr_NoData = 'kknd';

static AudioStreamBasicDescription KKSignedIntLinearPCMStreamDescription();

@interface KKSimpleAUPlayer () <NSURLConnectionDelegate>
{
    NSURLConnection *URLConnection;
    struct {
        BOOL stopped;
        BOOL loaded;
    } playerStatus ;
    
    AUGraph audioGraph;
    AudioUnit mixerUnit;
    AudioUnit EQUnit;
    AudioUnit outputUnit;
    
    AudioFileStreamID audioFileStreamID;
    AudioStreamBasicDescription streamDescription;
    AudioConverterRef converter;
    AudioBufferList *renderBufferList;
    UInt32 renderBufferSize;
    
    
    size_t readHead;
    NSString *recoderPath;
    NSString *dspPath;
    FILE *pcmfp;
    FILE *dspfp;
    dispatch_queue_t _queue;
    BOOL stopState;
    int _nMaxLen;
@public
    BOOL enableState;
    float _agcLevel;
    int _denoise;
    int _agc;
    int _vad;
}
@property(readwrite)Float32        samplingRate;
@property (readwrite) Float32      outputVolume;
@property(nonatomic,copy)NSString *postFileName;
@property(nonatomic,copy)NSString *preFileName;
@property (strong, nonatomic)  NSMutableArray *packetArrays;
- (double)packetsPerSecond;
@end

AudioStreamBasicDescription KKSignedIntLinearPCMStreamDescription()
{
    AudioStreamBasicDescription destFormat;
    bzero(&destFormat, sizeof(AudioStreamBasicDescription));
    destFormat.mSampleRate = 44100;//44100;
    // destFormat.mSampleRate = 16000;//44100;
    destFormat.mFormatID = kAudioFormatLinearPCM;
    destFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger;
    destFormat.mFramesPerPacket = 1;
    destFormat.mBytesPerPacket = 4;
    destFormat.mBytesPerFrame = 4;
    destFormat.mChannelsPerFrame = 2;
    destFormat.mBitsPerChannel = 16;
    destFormat.mReserved = 0;
    return destFormat;
}

@implementation KKSimpleAUPlayer

- (void)dealloc
{

    AUGraphUninitialize(audioGraph);
    AUGraphClose(audioGraph);
    DisposeAUGraph(audioGraph);
    
    AudioFileStreamClose(audioFileStreamID);
    AudioConverterDispose(converter);
    free(renderBufferList->mBuffers[0].mData);
    free(renderBufferList);
    renderBufferList = NULL;
}

- (BOOL) checkAudioRoute
{
    // Check what the audio route is.
    UInt32 propertySize = sizeof(CFStringRef);
    CFStringRef route;
    AudioSessionGetProperty(kAudioSessionProperty_AudioRoute,
                            &propertySize,
                            &route);
    return YES;
}

- (void)buildOutputUnit
{
     _queue = dispatch_queue_create("ulife.audioUnit.queue", DISPATCH_QUEUE_SERIAL);
    _nMaxLen = 30;
    stopState = YES;
    
    self.postFileName = [NSTemporaryDirectory() stringByAppendingPathComponent:g_postFileName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.postFileName]) {
        [[NSFileManager defaultManager] removeItemAtPath:self.postFileName error:nil];
    }
    
    self.preFileName = [NSTemporaryDirectory() stringByAppendingPathComponent:g_preFileName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.preFileName]) {
        [[NSFileManager defaultManager] removeItemAtPath:self.preFileName error:nil];
    }
    
    UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;
    AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory);
    UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
    AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute, sizeof(audioRouteOverride), &audioRouteOverride);
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    //默认情况下扬声器播放
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    [audioSession setActive:YES error:nil];
    
    //   AudioSessionAddPropertyListener(kAudioSessionProperty_CurrentHardwareOutputVolume,
    //                                                   sessionPropertyListener,
    //                                   (__bridge void *)(self));
    
    [self setInputGain:1.0f];
    int size = sizeof(_outputVolume);
    AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareOutputVolume,
                            &size,
                            &_outputVolume);
    // 建立 AudioGraph
    OSStatus status = NewAUGraph(&audioGraph);
    NSAssert(noErr == status, @"We need to create a new audio graph. %d", (int)status);
    status = AUGraphOpen(audioGraph);
    NSAssert(noErr == status, @"We need to open the audio graph. %d", (int)status);
    
    // 建立 mixer node
    AudioComponentDescription mixerUnitDescription;
    mixerUnitDescription.componentType= kAudioUnitType_Mixer;
    mixerUnitDescription.componentSubType = kAudioUnitSubType_MultiChannelMixer;
    mixerUnitDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    mixerUnitDescription.componentFlags = 0;
    mixerUnitDescription.componentFlagsMask = 0;
    AUNode mixerNode;
    status = AUGraphAddNode(audioGraph, &mixerUnitDescription, &mixerNode);
    NSAssert(noErr == status, @"We need to add the mixer node. %d", (int)status);
    
    // 建立 EQ node
    AudioComponentDescription EQUnitDescription;
    EQUnitDescription.componentType= kAudioUnitType_Effect;
    EQUnitDescription.componentSubType = kAudioUnitSubType_AUiPodEQ;
    EQUnitDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    EQUnitDescription.componentFlags = 0;
    EQUnitDescription.componentFlagsMask = 0;
    AUNode EQNode;
    status = AUGraphAddNode(audioGraph, &EQUnitDescription, &EQNode);
    NSAssert(noErr == status, @"We need to add the EQ effect node. %d", (int)status);
    
    // 建立 remote IO node
    AudioComponentDescription outputUnitDescription;
    bzero(&outputUnitDescription, sizeof(AudioComponentDescription));
    outputUnitDescription.componentType = kAudioUnitType_Output;
    outputUnitDescription.componentSubType = kAudioUnitSubType_VoiceProcessingIO;//kAudioUnitSubType_RemoteIO;
    outputUnitDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    outputUnitDescription.componentFlags = 0;
    outputUnitDescription.componentFlagsMask = 0;
    AUNode outputNode;
    status = AUGraphAddNode(audioGraph, &outputUnitDescription, &outputNode);
    NSAssert(noErr == status, @"We need to add an output node to the audio graph. %d", (int)status);
    
    // 將 mixer node 連接到 EQ node
    status = AUGraphConnectNodeInput(audioGraph, mixerNode, 0, EQNode, 0);
    NSAssert(noErr == status, @"We need to connect the nodes within the audio graph. %d", (int)status);
    
    // 將 EQ node 連接到 Remote IO
    status = AUGraphConnectNodeInput(audioGraph, EQNode, 0, outputNode, 0);
    NSAssert(noErr == status, @"We need to connect the nodes within the audio graph. %d", (int)status);
    
    
    // 拿出 Remote IO 的 Audio Unit
    status = AUGraphNodeInfo(audioGraph, outputNode, &outputUnitDescription, &outputUnit);
    NSAssert(noErr == status, @"We need to get the audio unit of the output node. %d", (int)status);
    // 拿出 EQ node 的 Audio Unit
    status = AUGraphNodeInfo(audioGraph, EQNode, &EQUnitDescription, &EQUnit);
    NSAssert(noErr == status, @"We need to get the audio unit of the EQ effect node. %d", (int)status);
    // 拿出 mixer node 的 Audio Unit
    status = AUGraphNodeInfo(audioGraph, mixerNode, &mixerUnitDescription, &mixerUnit);
    NSAssert(noErr == status, @"We need to get the audio unit of the mixer node. %d", (int)status);
    
    // 設定 mixer node 的輸入輸出格式
    AudioStreamBasicDescription audioFormat = KKSignedIntLinearPCMStreamDescription();
    status = AudioUnitSetProperty(mixerUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &audioFormat, sizeof(audioFormat));
    NSAssert(noErr == status, @"We need to set input format of the mixer node. %d", (int)status);
    status = AudioUnitSetProperty(mixerUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &audioFormat, sizeof(audioFormat));
    NSAssert(noErr == status, @"We need to set input format of the mixer effect node. %d", (int)status);
    
    // 設定 EQ node 的輸入輸出格式
    status = AudioUnitSetProperty(EQUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &audioFormat, sizeof(audioFormat));
    NSAssert(noErr == status, @"We need to set input format of the EQ node. %d", (int)status);
    status = AudioUnitSetProperty(EQUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &audioFormat, sizeof(audioFormat));
    NSAssert(noErr == status, @"We need to set input format of the EQ effect node. %d", (int)status);
    
    // 設定 Remote IO node 的輸入格式
    status = AudioUnitSetProperty(outputUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &audioFormat, sizeof(audioFormat));
    NSAssert(noErr == status, @"We need to set input format of the  remote IO node. %d", (int)status);
    
    // 設定 maxFPS
    UInt32 maxFPS = 4096;
    status = AudioUnitSetProperty(mixerUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0,&maxFPS, sizeof(maxFPS));
    NSAssert(noErr == status, @"We need to set the maximum FPS to the mixer node. %d", (int)status);
    status = AudioUnitSetProperty(EQUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0,&maxFPS, sizeof(maxFPS));
    NSAssert(noErr == status, @"We need to set the maximum FPS to the EQ effect node. %d", (int)status);
    status = AudioUnitSetProperty(outputUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0,&maxFPS, sizeof(maxFPS));
    NSAssert(noErr == status, @"We need to set the maximum FPS to the EQ effect node. %d", (int)status);
    
    Float32 preferredBufferSize = 0.0232;
    AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration,
                            sizeof(preferredBufferSize),
                            &preferredBufferSize);
    // 設定 render callback
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProcRefCon = (__bridge void *)(self);
    callbackStruct.inputProc = KKPlayerAURenderCallback;
    status = AUGraphSetNodeInputCallback(audioGraph, mixerNode, 0, &callbackStruct);
    NSAssert(noErr == status, @"Must be no error.");
    
    [self enableInput:0 isOn:1.0f];
    [self setInputVolume:0 value:0.7];
    [self setOutputVolume:0.7f];
    
    OSStatus err = AudioUnitSetParameter( mixerUnit,
                                         kHALOutputParam_Volume,
                                         kAudioUnitScope_Global,
                                         0,
                                         1.0f,
                                         0 );
    if ( err != noErr ) {
        NSLog( @"AudioUnitSetParameter(kHALOutputParam_Volume) failed. err=%d\n", err );
    }
    
    
    int echoCancellation = 1;
    int Unitsize = sizeof(echoCancellation);
    AudioUnitGetProperty(mixerUnit,
                                    kAUVoiceIOProperty_BypassVoiceProcessing,
                                    kAudioUnitScope_Global,
                                    0,
                                    &echoCancellation,
                                    &Unitsize);
    
    UInt32 audioAGC = 1;
    err = AudioUnitSetProperty(mixerUnit, kAUVoiceIOProperty_VoiceProcessingEnableAGC,
                                  kAudioUnitScope_Global,
                                           0,
                                           &audioAGC,
                                           sizeof(audioAGC));
    
    //Non Audio Voice Ducking
    UInt32 audioDucking = 1;
    err = AudioUnitSetProperty(mixerUnit, kAUVoiceIOProperty_DuckNonVoiceAudio,
                                  kAudioUnitScope_Global, 0, &audioDucking, sizeof(audioDucking));
    
//    //Audio Quality
    UInt32 quality = 127;
    err = AudioUnitSetProperty(mixerUnit, kAUVoiceIOProperty_VoiceProcessingQuality,
                                  kAudioUnitScope_Global, 0, &quality, sizeof(quality));
    
    //    // Set pan
    //    AudioUnitSetParameter(mixerUnit, kMultiChannelMixerParam_Pan, kAudioUnitScope_Input, 0, 1.0, 0);
    
    status = AUGraphInitialize(audioGraph);
//    NSAssert(noErr == status, @"Must be no error.");
    
    //  建立 converter 要使用的 buffer list
    UInt32 bufferSize = 4096 * 4;
    renderBufferSize = bufferSize;
    renderBufferList = (AudioBufferList *)calloc(1, sizeof(UInt32) + sizeof(AudioBuffer));
    renderBufferList->mNumberBuffers = 1;
    renderBufferList->mBuffers[0].mNumberChannels = 2;
    renderBufferList->mBuffers[0].mDataByteSize = bufferSize;
    renderBufferList->mBuffers[0].mData = calloc(1, bufferSize);
    //CAShow(audioGraph);
}

-(void)setInputGain:(float)inputGain {
    NSError *error = NULL;
    if ( ![((AVAudioSession*)[AVAudioSession sharedInstance]) setInputGain:inputGain error:&error] ) {
        NSLog(@"TAAE: Couldn't set input gain: %@", error);
    }
}

-(void)enableSpeexState:(BOOL)state
{
    enableState = state;
}

- (void)enableInput:(UInt32)inputNum isOn:(AudioUnitParameterValue)isONValue
{
    //printf("BUS %d isON %f\n", (unsigned int)inputNum, isONValue);
    OSStatus result = AudioUnitSetParameter(mixerUnit, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, inputNum, isONValue, 0);
    if (result) { printf("AudioUnitSetParameter kMultiChannelMixerParam_Enable result %ld %08lX %4.4s\n", (long)result, (long)result, (char*)&result); return; }
}

// sets the input volume for a specific bus
- (void)setInputVolume:(UInt32)inputNum value:(AudioUnitParameterValue)value
{
    //NSLog(@"inputNum = %d",inputNum);
    OSStatus result = AudioUnitSetParameter(mixerUnit, kMultiChannelMixerParam_Volume, kAudioUnitScope_Input, inputNum, value, 0);
    if (result) { printf("AudioUnitSetParameter kMultiChannelMixerParam_Volume Input result %ld %08lX %4.4s\n", (long)result, (long)result, (char*)&result); return; }
}


//// sets the overall mixer output volume kMultiChannelMixerParam_Volume
- (void)setOutputVolume:(AudioUnitParameterValue)value
{
    OSStatus result = AudioUnitSetParameter(mixerUnit, kMultiChannelMixerParam_Volume, kAudioUnitScope_Output, 0, value, 0);
    if (result) { printf("AudioUnitSetParameter kMultiChannelMixerParam_Volume Output result %ld %08lX %4.4s\n", (long)result, (long)result, (char*)&result); return; }
}

-(id)init
{
    self = [super init];
    if (self) {
        _outputVolume = 1.0;
        [self buildOutputUnit];
        enableState = YES;
        playerStatus.stopped = NO;
        _packetArrays = [[NSMutableArray alloc] init];
        
        // 第一步：建立 Audio Parser，指定 callback，以及建立 HTTP 連線，
        // 開始下載檔案
        AudioFileStreamOpen((__bridge void *)(self),
                            KKAudioFileStreamPropertyListener,
                            KKAudioFileStreamPacketsCallback,
                            kAudioFileAAC_ADTSType, &audioFileStreamID);
        playerStatus.stopped = YES;
        
        recoderPath = [NSTemporaryDirectory() stringByAppendingPathComponent:AudioFilePCM];
        dspPath = [NSTemporaryDirectory() stringByAppendingPathComponent:DspFilePCM];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setVolumeNotification:) name:VolumeNotification object:nil];
    }
    return self;
}

-(void)setVolumeNotification:(NSNotification*)notification
{
    //[self setOutputVolume:g_volce];
    // [self setInputVolume:0 value:g_volce];
}

-(void)playWith:(char*)audioBuffer andBufferLen:(int)len
{

    @synchronized(self) {
        AudioFileStreamParseBytes(audioFileStreamID, len,audioBuffer, 0);
    }
}

-(void)addNewData:(Byte*)buf len:(int)len
{
    if (stopState)
    {
        dispatch_sync(_queue, ^
          {
              @synchronized(self) {
                  if ([self.packetArrays count] < _nMaxLen)
                  {
                      @autoreleasepool {
                          NSData* data = [[NSData alloc] initWithBytes:buf length:len];
                          [_packetArrays addObject:data];
                      }
                  }
                  else
                  {
                      usleep(1000);
                  }
              }
          });
    }
    return;
}

-(void)getData:(Byte**)buf andLength:(int*)len
{
    if (stopState)
    {
        if (_queue)
        {
            dispatch_sync(_queue, ^
              {
                  @synchronized(self) {
                      // 被锁住的代码
                      if ([self.packetArrays count] > 0)
                      {
                          @autoreleasepool
                          {
                                  NSData *packet = [_packetArrays objectAtIndex:0];
                                  if (packet){
                                      int length = (int)[packet length];
                                      *len = length;
                                      *buf = malloc(length);
                                      memcpy(*buf, [packet bytes], length);
                                      [_packetArrays removeObjectAtIndex:0];
                                  }
                            }
                      }
                      else
                      {
                          usleep(1000);
                      }
                  }
              }
            );
        }
    }
    return;
}

-(void)clearBuffer
{
    stopState = NO;
    @synchronized(self)
    {
        NSLog(@"clearBuffer--1");
        if ([self.packetArrays count] > 0)
        {
            // 被锁住的代码
            if (_queue != nil)
            {
                dispatch_async(_queue, ^
                   {
                       if ([_packetArrays count] > 0) {
                           for (int i = 0; i < [_packetArrays count]; i++) {
                               @autoreleasepool {
                                   NSData *head = [_packetArrays objectAtIndex:i];
                                   [_packetArrays removeObject:head];
//                                   [head release];
                               }
                           }
                           
                       }
                   });
            }
        }
        else
        {
        }
    }
}


- (double)packetsPerSecond
{
    if (streamDescription.mFramesPerPacket) {
        return streamDescription.mSampleRate / streamDescription.mFramesPerPacket;
    }
    return 44100.0/1152.0;
}

- (void)play
{
    
    if (!playerStatus.stopped) {
        return;
    }
    
    OSStatus status = AUGraphStart(audioGraph);
    NSAssert(noErr == status, @"AUGraphStart, error: %ld", (signed long)status);
    status = AudioOutputUnitStart(outputUnit);
    NSAssert(noErr == status, @"AudioOutputUnitStart, error: %ld", (signed long)status);
    playerStatus.stopped = NO;
}

- (void)pause
{
    playerStatus.stopped = YES;
    [self clearBuffer];
    if (_queue) {
        _queue = nil;
    }
    OSStatus status = AUGraphStop(audioGraph);
    NSAssert(noErr == status, @"AUGraphStart, error: %ld", (signed long)status);
    status = AudioOutputUnitStop(outputUnit);
    NSAssert(noErr == status, @"AudioOutputUnitStop, error: %ld", (signed long)status);
    goscam_dsp_stop();
}

- (CFArrayRef)iPodEQPresetsArray
{
    CFArrayRef array;
    UInt32 size = sizeof(array);
    AudioUnitGetProperty(EQUnit, kAudioUnitProperty_FactoryPresets, kAudioUnitScope_Global, 0, &array, &size);
    return array;
}

- (void)selectEQPreset:(NSInteger)value
{
    AUPreset *aPreset = (AUPreset*)CFArrayGetValueAtIndex(self.iPodEQPresetsArray, value);
    AudioUnitSetProperty(EQUnit, kAudioUnitProperty_PresentPreset, kAudioUnitScope_Global, 0, aPreset, sizeof(AUPreset));
}

#pragma mark -
#pragma mark Audio Parser and Audio Queue callbacks

- (void)_createAudioQueueWithAudioStreamDescription:(AudioStreamBasicDescription *)audioStreamBasicDescription
{
    memcpy(&streamDescription, audioStreamBasicDescription, sizeof(AudioStreamBasicDescription));
    AudioStreamBasicDescription destFormat = KKSignedIntLinearPCMStreamDescription();
    AudioConverterNew(&streamDescription, &destFormat, &converter);
}

- (void)_storePacketsWithNumberOfBytes:(UInt32)inNumberBytes
                       numberOfPackets:(UInt32)inNumberPackets
                             inputData:(const void *)inInputData
                    packetDescriptions:(AudioStreamPacketDescription *)inPacketDescriptions
{
    for (int i = 0; i < inNumberPackets; ++i) {
        SInt64 packetStart = inPacketDescriptions[i].mStartOffset;
        UInt32 packetSize = inPacketDescriptions[i].mDataByteSize;
        assert(packetSize > 0);
//        NSData *packet = [NSData dataWithBytes:inInputData + packetStart length:packetSize];
//        [packets addObject:packet];
        [self addNewData:(inInputData + packetStart) len:packetSize];
    }
    //  第五步，因為 parse 出來的 packets 夠多，緩衝內容夠大，因此開始
    //  播放
    if (readHead == 0 && [_packetArrays count] > (int)([self packetsPerSecond] * 3))
    {
        if (playerStatus.stopped)
        {
            [self play];
        }
    }
}



#pragma mark -
#pragma mark Properties

- (BOOL)isStopped
{
    return playerStatus.stopped;
}

- (OSStatus)callbackWithNumberOfFrames:(UInt32)inNumberOfFrames
                                ioData:(AudioBufferList  *)inIoData busNumber:(UInt32)inBusNumber
                                state:(BOOL)state
{
    @synchronized(self)
    {
        if (self.packetArrays.count > 0)
        {
            @autoreleasepool
            {
                if (playerStatus.stopped) {
                    return 0;
                }
                UInt32 packetSize = inNumberOfFrames;
                goscam_dsp_nFramesPacket(inNumberOfFrames);
                // 第七步： Remote IO node 的 render callback 中，呼叫 converter 將 packet 轉成 LPCM
                OSStatus status =
                AudioConverterFillComplexBuffer(converter,
                                                KKPlayerConverterFiller,
                                                (__bridge void *)(self),
                                                &packetSize, renderBufferList, NULL);
                if (noErr != status && KKAudioConverterCallbackErr_NoData != status) {
//                    [self pause];
                    return -1;
                }
                else if (!packetSize) {
                    inIoData->mNumberBuffers = 0;
                }
                else
                {
                    //                  int write_length =  fwrite((char *)renderBufferList->mBuffers[0].mData,1, renderBufferList->mBuffers[0].mDataByteSize,pcmfp);
                    //NSLog(@"renderBufferList->mBuffers[0].mDataByteSize = %d",renderBufferList->mBuffers[0].mDataByteSize);
                    short *frame = (short *)renderBufferList->mBuffers[0].mData;
                    int lenth = renderBufferList->mBuffers[0].mDataByteSize;
                    int len = lenth;
                    if (state) {
                        len = lenth/2.0;
                        goscam_dsp_handle(frame, len, g_mSampleRate);
                    }
                    
                    //                    fwrite((char *)renderBufferList->mBuffers[0].mData,1, renderBufferList->mBuffers[0].mDataByteSize,dspfp);
                    
                    inIoData->mNumberBuffers = 1;
                    inIoData->mBuffers[0].mNumberChannels = 2;
                    inIoData->mBuffers[0].mDataByteSize = lenth;
                    inIoData->mBuffers[0].mData = frame;
                    renderBufferList->mBuffers[0].mDataByteSize = renderBufferSize;
                }
            }
        }
        else {
            inIoData->mNumberBuffers = 0;
            return -1;
        }
    }
    
    return noErr;
}


- (OSStatus)_fillConverterBufferWithBufferlist:(AudioBufferList *)ioData
                             packetDescription:(AudioStreamPacketDescription** )outDataPacketDescription
                                         state:(BOOL)state
{
    static AudioStreamPacketDescription aspdesc;
    
//    if (readHead >= [packets count])
//    {
//        return KKAudioConverterCallbackErr_NoData;
//    }
    
    ioData->mNumberBuffers = 1;
    int length = 0;
    Byte* buffer = nil;
    [self getData:&buffer andLength:&length];
    if (length > 0 && buffer != nil)
    {
        ioData->mBuffers[0].mData = (void *)buffer;
        ioData->mBuffers[0].mDataByteSize = length;
        *outDataPacketDescription = &aspdesc;
        aspdesc.mDataByteSize = length;
        aspdesc.mStartOffset = 0;
        aspdesc.mVariableFramesInPacket = 1;
        readHead++;
    }
    return 0;
}

-(void)setAgcLevel:(float)agcLevel
{
    _agcLevel = agcLevel;
}
-(void)setDenoies:(int)flag
{
    _denoise = flag;
}

-(void)setAgc:(int)agc
{
    _agc = agc;
}

-(void)setVad:(int)vad
{
    _vad = vad;
}
@end

void KKAudioFileStreamPropertyListener(void * inClientData,
                                       AudioFileStreamID inAudioFileStream,
                                       AudioFileStreamPropertyID inPropertyID,
                                       UInt32 * ioFlags)
{
    KKSimpleAUPlayer *self = (__bridge KKSimpleAUPlayer *)inClientData;
    if (inPropertyID == kAudioFileStreamProperty_DataFormat) {
        UInt32 dataSize  = 0;
        OSStatus status = 0;
        AudioStreamBasicDescription audioStreamDescription;
        Boolean writable = false;
        status = AudioFileStreamGetPropertyInfo(inAudioFileStream,
                                                kAudioFileStreamProperty_DataFormat, &dataSize, &writable);
        status = AudioFileStreamGetProperty(inAudioFileStream,
                                            kAudioFileStreamProperty_DataFormat, &dataSize, &audioStreamDescription);

        g_mSampleRate = audioStreamDescription.mSampleRate;
        NSLog(@"mSampleRate: %f", audioStreamDescription.mSampleRate);
        NSLog(@"mFormatID: %u", audioStreamDescription.mFormatID);
        NSLog(@"mFormatFlags: %u", audioStreamDescription.mFormatFlags);
        NSLog(@"mBytesPerPacket: %u", audioStreamDescription.mBytesPerPacket);
        NSLog(@"mFramesPerPacket: %u", audioStreamDescription.mFramesPerPacket);
        NSLog(@"mBytesPerFrame: %u", audioStreamDescription.mBytesPerFrame);
        NSLog(@"mChannelsPerFrame: %u", audioStreamDescription.mChannelsPerFrame);
        NSLog(@"mBitsPerChannel: %u", audioStreamDescription.mBitsPerChannel);
        NSLog(@"mReserved: %u", audioStreamDescription.mReserved);
        
        goscam_dsp_start(audioStreamDescription.mSampleRate,(char *)[self.preFileName UTF8String],(char *)[self.postFileName UTF8String]);

//        DspCtrl *ctrl =  getDspCtrl();
//        ctrl->agcLevel = self->_agcLevel;
//        ctrl->denoise =self->_denoise;
//        ctrl->agc = self->_agc;
//        ctrl->vad = self->_vad;
//        processDspCtrl();
        
        // 第三步： Audio Parser 成功 parse 出 audio 檔案格式，我們根據
        // 檔案格式資訊，建立 converter
        [self _createAudioQueueWithAudioStreamDescription:&audioStreamDescription];
    }
}

void KKAudioFileStreamPacketsCallback(void* inClientData,
                                      UInt32 inNumberBytes,
                                      UInt32 inNumberPackets,
                                      const void* inInputData,
                                      AudioStreamPacketDescription* inPacketDescriptions)
{
    // 第四步： Audio Parser 成功 parse 出 packets，我們將這些資料儲存
    // 起來
    
    KKSimpleAUPlayer *self = (__bridge KKSimpleAUPlayer *)inClientData;
    [self _storePacketsWithNumberOfBytes:inNumberBytes
                         numberOfPackets:inNumberPackets
                               inputData:inInputData
                      packetDescriptions:inPacketDescriptions];
}

OSStatus KKPlayerAURenderCallback(void *userData,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData)
{
    // 第六步： Remote IO node 的 render callback
    KKSimpleAUPlayer *self = (__bridge KKSimpleAUPlayer *)userData;
    OSStatus status = [self callbackWithNumberOfFrames:inNumberFrames
                                                ioData:ioData busNumber:inBusNumber state:self->enableState];
    if (status != noErr) {
        ioData->mNumberBuffers = 0;
        *ioActionFlags |= kAudioUnitRenderAction_OutputIsSilence;
    }
    return status;
}

OSStatus KKPlayerConverterFiller (AudioConverterRef inAudioConverter,
                                  UInt32* ioNumberDataPackets,
                                  AudioBufferList* ioData,
                                  AudioStreamPacketDescription** outDataPacketDescription,
                                  void* inUserData)
{
    // 第八步： AudioConverterFillComplexBuffer 的 callback
    KKSimpleAUPlayer *self = (__bridge KKSimpleAUPlayer *)inUserData;
    *ioNumberDataPackets = 0;
    OSStatus result = [self _fillConverterBufferWithBufferlist:ioData
                                             packetDescription:outDataPacketDescription state:self->enableState];
    if (result == noErr) {
        *ioNumberDataPackets = 1;
    }
    return result;
}


//static void sessionPropertyListener(void *                  inClientData,
//                                    AudioSessionPropertyID  inID,
//                                    UInt32                  inDataSize,
//                                    const void *            inData)
//{
//     KKSimpleAUPlayer *self = (__bridge KKSimpleAUPlayer *)inClientData;
//    
//    if (inID == kAudioSessionProperty_AudioRouteChange) {
//        
//    } else if (inID == kAudioSessionProperty_CurrentHardwareOutputVolume) {
//        if (inData && inDataSize == 4) {
//            self.outputVolume = *(float *)inData;
//            NSLog(@"outputVolume = %f",self.outputVolume);
//        }
//    }
//}

static BOOL checkError(OSStatus error, const char *operation)
{
    if (error == noErr)
        return NO;
    
    char str[20] = {0};
    // see if it appears to be a 4-char-code
    *(UInt32 *)(str + 1) = CFSwapInt32HostToBig(error);
    if (isprint(str[1]) && isprint(str[2]) && isprint(str[3]) && isprint(str[4])) {
        str[0] = str[5] = '\'';
        str[6] = '\0';
    } else
        // no, format it as an integer
        sprintf(str, "%d", (int)error);
    //exit(1);
   // NSLog(@"str = %@"，);
    return YES;
}
