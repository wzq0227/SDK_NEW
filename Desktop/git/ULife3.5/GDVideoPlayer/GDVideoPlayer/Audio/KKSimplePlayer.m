//
//  KKSimplePlayer.m
//  GDVideoPlayer
//
//  Created by goscam on 16/3/15.
//  Copyright © 2016年 goscamtest. All rights reserved.
//


#import "KKSimplePlayer.h"
#import "GDVideoStateInfo.h"


static void KKAudioFileStreamPropertyListener(void * inClientData,
                                              AudioFileStreamID inAudioFileStream,
                                              AudioFileStreamPropertyID inPropertyID,
                                              UInt32 * ioFlags);
static void KKAudioFileStreamPacketsCallback(void * inClientData,
                                             UInt32 inNumberBytes,
                                             UInt32 inNumberPackets,
                                             const void * inInputData,
                                             AudioStreamPacketDescription *inPacketDescriptions);
static void KKAudioQueueOutputCallback(void * inUserData,
                                       AudioQueueRef inAQ,
                                       AudioQueueBufferRef inBuffer);
static void KKAudioQueueRunningListener(void * inUserData,
                                        AudioQueueRef inAQ,
                                        AudioQueuePropertyID inID);

@interface KKSimplePlayer ()
{
    NSURLConnection *URLConnection;
    struct {
        BOOL stopped;
        BOOL loaded;
    } playerStatus ;
    float volume;
    AudioFileStreamID audioFileStreamID;
    AudioQueueRef outputQueue;
    AudioStreamBasicDescription streamDescription;
    NSMutableArray *packets;
    size_t readHead;
}
- (double)packetsPerSecond;
@end

@implementation KKSimplePlayer

- (void)dealloc
{
    AudioQueueReset(outputQueue);
    AudioFileStreamClose(audioFileStreamID);
}

-(id)init
{
    self = [super init];
    if (self) {
        packets = [[NSMutableArray alloc] init];
        // 第一步：建立 Audio Parser，指定 callback，以及建立 HTTP 連線，
        // 開始下載檔案
        AudioFileStreamOpen((__bridge void * _Nullable)(self),
                            KKAudioFileStreamPropertyListener,
                            KKAudioFileStreamPacketsCallback,
                            kAudioFileMP3Type, &audioFileStreamID);
        volume = 50.f;
    }
    return self;
}

- (double)packetsPerSecond
{
    NSLog(@"mSampleRate = %f,mFramesPerPacket = %d",streamDescription.mSampleRate,(unsigned int)streamDescription.mFramesPerPacket);
    if (streamDescription.mFramesPerPacket) {
        NSLog(@"packetsPerSecond = %f",streamDescription.mSampleRate / streamDescription.mFramesPerPacket);
        return streamDescription.mSampleRate / streamDescription.mFramesPerPacket;
    }
    return 3200.0/1152.0;
}

- (void)play
{
    AudioQueueStart(outputQueue, NULL);
    volume = g_volce;
    OSStatus result = AudioQueueSetParameter(outputQueue, kAudioQueueParam_Volume, volume);
}

- (void)pause
{
    AudioQueuePause(outputQueue);
}

#pragma mark -
#pragma mark NSURLConnectionDelegate
-(void)playWith:(char*)audioBuffer andBufferLen:(int)len
{
    @synchronized(self) {
        OSStatus audioplayerErr = AudioFileStreamParseBytes(audioFileStreamID, len, audioBuffer, 0);
        if (audioplayerErr)
        {
            printf("AudioFileStreamParseBytes");
        }
    }
}

#pragma mark -
#pragma mark Audio Parser and Audio Queue callbacks
- (void)_enqueueDataWithPacketsCount:(size_t)inPacketCount
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    if (!outputQueue) {
        return;
    }
    
//    if (readHead == [packets count]) {
//        // 第六步：已經把所有 packet 都播完了，檔案播放結束。
//        AudioQueueReset(outputQueue);
//        readHead = 0;
//        return;
//    }
    
    if (readHead + inPacketCount >= [packets count]) {
        inPacketCount = [packets count] - readHead;
    }
    
    UInt32 totalSize = 0;
    UInt32 index;
    
    for (index = 0 ; index < inPacketCount ; index++) {
        NSData *packet = packets[index + readHead];
        totalSize += packet.length;
    }
    
    OSStatus status = 0;
    AudioQueueBufferRef buffer;
    status = AudioQueueAllocateBuffer(outputQueue, totalSize, &buffer);
    assert(status == noErr);
    buffer->mAudioDataByteSize = totalSize;
    buffer->mUserData = (__bridge void * _Nullable)(self);
    
    AudioStreamPacketDescription *packetDescs = calloc(inPacketCount,
                                                       sizeof(AudioStreamPacketDescription));
    totalSize = 0;
    for (index = 0 ; index < inPacketCount ; index++) {
        size_t readIndex = index + readHead;
        NSData *packet = packets[readIndex];
        memcpy(buffer->mAudioData + totalSize, packet.bytes, packet.length);
        AudioStreamPacketDescription description;
        description.mStartOffset = totalSize;
        description.mDataByteSize = packet.length;
        description.mVariableFramesInPacket = 0;
        totalSize += packet.length;
        memcpy(&(packetDescs[index]), &description, sizeof(AudioStreamPacketDescription));
//        [packets removeObject:packet];
//        [packet release];
    }
    status = AudioQueueEnqueueBuffer(outputQueue, buffer, (UInt32)inPacketCount, packetDescs);
    free(packetDescs);
    AudioQueueFreeBuffer(outputQueue,buffer);
    for (int i = readHead;  i < [packets count];i++) {
        NSData *packet = packets[i];
        if (packet) {
            packet = nil;
            [packets removeObjectAtIndex:i];
        }
    }
//    readHead += inPacketCount;
    readHead = 0;
}

- (void)_createAudioQueueWithAudioStreamDescription:(AudioStreamBasicDescription *)audioStreamBasicDescription
{
    memcpy(&streamDescription, audioStreamBasicDescription, sizeof(AudioStreamBasicDescription));
    OSStatus status = AudioQueueNewOutput(audioStreamBasicDescription,
                                          KKAudioQueueOutputCallback,
                                          (__bridge void * _Nullable)(self),
                                          CFRunLoopGetCurrent(),
                                          kCFRunLoopCommonModes, 0, &outputQueue);
    assert(status == noErr);
    status = AudioQueueAddPropertyListener(outputQueue,
                                           kAudioQueueProperty_IsRunning,
                                           KKAudioQueueRunningListener,
                                           (__bridge void * _Nullable)(self));
    AudioQueuePrime(outputQueue, 0, NULL);
    AudioQueueStart(outputQueue, NULL);
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
        NSData *packet = [NSData dataWithBytes:inInputData + packetStart length:packetSize];
        [packets addObject:packet];
    }
    
    //  第五步，因為 parse 出來的 packets 夠多，緩衝內容夠大，因此開始
    //  播放
//    NSLog(@"count = %d",[packets count]);
//    if ([packets count] > 2 && readHead == 0) {
//        AudioQueueStart(outputQueue, NULL);
//        [self _enqueueDataWithPacketsCount: 2];
//    }
    
    if ([packets count] > (int)([self packetsPerSecond])) {
        //AudioQueueStart(outputQueue, NULL);
        if(((volume - g_volce) >= - EPSINON) && ((volume - g_volce) <= EPSINON)){
            
        }
        else
        {
            volume = g_volce;
            OSStatus result = AudioQueueSetParameter(outputQueue, kAudioQueueParam_Volume, volume);
        }
        [self _enqueueDataWithPacketsCount: (int)([self packetsPerSecond])];
    }
}

- (void)_audioQueueDidStart
{
    NSLog(@"Audio Queue did start");
}

- (void)_audioQueueDidStop
{
    NSLog(@"Audio Queue did stop");
    playerStatus.stopped = YES;
}

#pragma mark -
#pragma mark Properties

- (BOOL)isStopped
{
    return playerStatus.stopped;
}

@end

void KKAudioFileStreamPropertyListener(void * inClientData,
                                       AudioFileStreamID inAudioFileStream,
                                       AudioFileStreamPropertyID inPropertyID,
                                       UInt32 * ioFlags)
{
    KKSimplePlayer *self = (__bridge KKSimplePlayer *)inClientData;
    if (inPropertyID == kAudioFileStreamProperty_DataFormat) {
        UInt32 dataSize  = 0;
        OSStatus status = 0;
        AudioStreamBasicDescription audioStreamDescription;
        Boolean writable = false;
        status = AudioFileStreamGetPropertyInfo(inAudioFileStream,
                                                kAudioFileStreamProperty_DataFormat,
                                                &dataSize, &writable);
        status = AudioFileStreamGetProperty(inAudioFileStream,
                                            kAudioFileStreamProperty_DataFormat,
                                            &dataSize, &audioStreamDescription);
        
        NSLog(@"mSampleRate: %f", audioStreamDescription.mSampleRate);
        NSLog(@"mFormatID: %u", audioStreamDescription.mFormatID);
        NSLog(@"mFormatFlags: %u", audioStreamDescription.mFormatFlags);
        NSLog(@"mBytesPerPacket: %u", audioStreamDescription.mBytesPerPacket);
        NSLog(@"mFramesPerPacket: %u", audioStreamDescription.mFramesPerPacket);
        NSLog(@"mBytesPerFrame: %u", audioStreamDescription.mBytesPerFrame);
        NSLog(@"mChannelsPerFrame: %u", audioStreamDescription.mChannelsPerFrame);
        NSLog(@"mBitsPerChannel: %u", audioStreamDescription.mBitsPerChannel);
        NSLog(@"mReserved: %u", audioStreamDescription.mReserved);
        
        // 第三步： Audio Parser 成功 parse 出 audio 檔案格式，我們根據
        // 檔案格式資訊，建立 Audio Queue，同時監聽 Audio Queue 是否正
        // 在執行
        
        [self _createAudioQueueWithAudioStreamDescription:&audioStreamDescription];
    }
}

void KKAudioFileStreamPacketsCallback(void * inClientData,
                                      UInt32 inNumberBytes,
                                      UInt32 inNumberPackets,
                                      const void * inInputData,
                                      AudioStreamPacketDescription *inPacketDescriptions)
{
    // 第四步： Audio Parser 成功 parse 出 packets，我們將這些資料儲存
    // 起來
    
    KKSimplePlayer *self = (__bridge KKSimplePlayer *)inClientData;
    [self _storePacketsWithNumberOfBytes:inNumberBytes
                         numberOfPackets:inNumberPackets
                               inputData:inInputData
                      packetDescriptions:inPacketDescriptions];
}

static void KKAudioQueueOutputCallback(void * inUserData,
                                       AudioQueueRef inAQ,AudioQueueBufferRef inBuffer)
{
    AudioQueueFreeBuffer(inAQ, inBuffer);
    KKSimplePlayer *self = (__bridge KKSimplePlayer *)inUserData;
    [self _enqueueDataWithPacketsCount:(int)([self packetsPerSecond] * 5)];
}

static void KKAudioQueueRunningListener(void * inUserData,
                                        AudioQueueRef inAQ, AudioQueuePropertyID inID)
{
    KKSimplePlayer *self = (__bridge KKSimplePlayer *)inUserData;
    UInt32 dataSize;
    OSStatus status = 0;
    status = AudioQueueGetPropertySize(inAQ, inID, &dataSize);
    if (inID == kAudioQueueProperty_IsRunning) {
        UInt32 running;
        status = AudioQueueGetProperty(inAQ, inID, &running, &dataSize);
        running ? [self _audioQueueDidStart] : [self _audioQueueDidStop];
    }
}
