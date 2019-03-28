//
//  UlifePlayerAudioDecoder.m
//  GVAP iPhone
//
//  Created by  on 12-4-11.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "GDAudioDecoder.h"
#import "GDVideoStateInfo.h"

WriteTxt* _myWriter;

//歌曲信息解析的回调，每解析出一个歌曲信息都会进行一次回调；
void MyPropertyListenerProc(	void *						inClientData,
                            AudioFileStreamID				inAudioFileStream,
                            AudioFileStreamPropertyID		inPropertyID,
                            UInt32 *						ioFlags)
{
    
    // this is called by audio file stream when it finds property values
    MyData* myData = (MyData*)inClientData;
    //	UInt32 inPropertySize = sizeof(AudioStreamBasicDescription);
    //	AudioStreamBasicDescription inDescription;
    //
    //	OSStatus a = AudioFileStreamGetProperty(myData->audioFileStream, kAudioFileStreamProperty_DataFormat, &inPropertySize, &inDescription);
    //	if (a)
    //	{
    //		printf("AudioFileStreamGetProperty err");
    //		return NO;
    //	}
    
    OSStatus err = noErr;
    //	printf("found property '%u%u%u%u'\n",
    //           (inPropertyID>>24)&255, (inPropertyID>>16)&255, (inPropertyID>>8)&255, inPropertyID&255);
    // NSLog(@"inPropertyID = %d",inPropertyID);
    switch (inPropertyID) {
        case kAudioFileStreamProperty_ReadyToProducePackets :
        {
            // the file stream parser is now ready to produce audio packets.
            // get the stream format.
            AudioStreamBasicDescription asbd;
            UInt32 asbdSize = sizeof(asbd);
            err = AudioFileStreamGetProperty(inAudioFileStream, kAudioFileStreamProperty_DataFormat, &asbdSize, &asbd);
            if (err){
                perror("get kAudioFileStreamProperty_DataFormat");
                myData->failed = true;
                NSLog(@"myData->failed 3");
                break;
            }
            
            //			asbd.mChannelsPerFrame = 1;
            //			err = AudioFileStreamSetProperty(inAudioFileStream, kAudioFileStreamProperty_DataFormat, asbdSize, &asbd);
            //			if (err) { perror("get kAudioFileStreamProperty_DataFormat"); myData->failed = true; break; }
            //
            char* str = malloc(500);
            sprintf(str, "mSampleRate:\t\t%f, \nmChannelsPerFrame:\t\t%u, \nmBitsPerChannel:\t\t%u\n\n",
                    asbd.mSampleRate, (unsigned int)asbd.mChannelsPerFrame, (unsigned int)asbd.mBitsPerChannel);
            
            // create the audio queue
            err = AudioQueueNewOutput(&asbd, MyAudioQueueOutputCallback, myData, NULL, NULL, 0, &myData->audioQueue);
            if (err) {
                perror("AudioQueueNewOutput");
                myData->failed = true;
                NSLog(@"myData->failed 4");
                break;
            }
            
            // allocate audio queue buffers
            for (unsigned int i = 0; i < kNumAQBufs; ++i) {
                err = AudioQueueAllocateBuffer(myData->audioQueue, kAQBufSize, &myData->audioQueueBuffer[i]);
                if (err) { perror("AudioQueueAllocateBuffer"); myData->failed = true;NSLog(@"myData->failed 5"); break; }
            }
            
            // get the cookie size
            //			UInt32 cookieSize;
            //			Boolean writable;
            //			err = AudioFileStreamGetPropertyInfo(inAudioFileStream, kAudioFileStreamProperty_MagicCookieData, &cookieSize, &writable);
            //			if (err) { perror("info kAudioFileStreamProperty_MagicCookieData"); break; }
            //			printf("cookieSize %lu\n", cookieSize);
            //
            //			// get the cookie data
            //			void* cookieData = calloc(1, cookieSize);
            //			err = AudioFileStreamGetProperty(inAudioFileStream, kAudioFileStreamProperty_MagicCookieData, &cookieSize, cookieData);
            //			if (err) { perror("get kAudioFileStreamProperty_MagicCookieData"); free(cookieData); break; }
            //
            //			// set the cookie on the queue.
            //
            //			err = AudioQueueSetProperty(myData->audioQueue, kAudioQueueProperty_MagicCookie, cookieData, cookieSize);
            //			free(cookieData);
            //			if (err) { perror("set kAudioQueueProperty_MagicCookie"); break; }
            
            UInt32 val = kAudioQueueHardwareCodecPolicy_PreferHardware;//在软解码不可用的情况下用硬解码
            OSStatus ignorableError;
            ignorableError = AudioQueueSetProperty(myData->audioQueue, kAudioQueueProperty_HardwareCodecPolicy, &val, sizeof(UInt32));
            //kAudioQueueProperty_HardwareCodecPolicy解码方式 软解还是硬解
            if (ignorableError)
            {
                return;
            }
            
            // listen for kAudioQueueProperty_IsRunning
            err = AudioQueueAddPropertyListener(myData->audioQueue, kAudioQueueProperty_IsRunning, MyAudioQueueIsRunningCallback, myData);
            if (err) { perror("AudioQueueAddPropertyListener"); myData->failed = true;NSLog(@"myData->failed 6"); break; }
            
            free(str);
            break;
        }
    }
}

void MyPacketsProc(	void *						inClientData,
                   UInt32						inNumberBytes,
                   UInt32						inNumberPackets,
                   const void *					inInputData,
                   AudioStreamPacketDescription	*inPacketDescriptions)
{
    // this is called by audio file stream when it finds packets of audio
    MyData* myData = (MyData*)inClientData;
    //NSLog(@"got data.  bytes: %u  packets: %u\n", (unsigned int)inNumberBytes, (unsigned int)inNumberPackets);
    
    // the following code assumes we're streaming VBR data. for CBR data, you'd need another code branch here.
    
    for (int i = 0; i < inNumberPackets; ++i) {
        SInt64 packetOffset = inPacketDescriptions[i].mStartOffset;
        SInt64 packetSize   = inPacketDescriptions[i].mDataByteSize;
        
        // if the space remaining in the buffer is not enough for this packet, then enqueue the buffer.
        size_t bufSpaceRemaining = kAQBufSize - myData->bytesFilled;
        if (bufSpaceRemaining < packetSize)
        {
            MyEnqueueBuffer(myData);
            WaitForFreeBuffer(myData);
        }
        
        // copy data to the audio queue buffer
        AudioQueueBufferRef fillBuf = myData->audioQueueBuffer[myData->fillBufferIndex];
        memcpy((char*)fillBuf->mAudioData + myData->bytesFilled, (const char*)inInputData + packetOffset, packetSize);
        
        // fill out packet description
        myData->packetDescs[myData->packetsFilled] = inPacketDescriptions[i];
        myData->packetDescs[myData->packetsFilled].mStartOffset = myData->bytesFilled;
        
        // keep track of bytes filled and packets filled
        myData->bytesFilled += packetSize;
        myData->packetsFilled += 1;
        
        //        NSLog(@"packetsFilled = %zu,myData->bytesFilled = %zu,bufSpaceRemaining = %zu",myData->packetsFilled,myData->bytesFilled,bufSpaceRemaining);
        
        // if that was the last free packet description, then enqueue the buffer.
        size_t packetsDescsRemaining = kAQMaxPacketDescs - myData->packetsFilled;
        if (packetsDescsRemaining == 0)
        {
            NSLog(@"packetsDescsRemaining == 0");
            MyEnqueueBuffer(myData);
            WaitForFreeBuffer(myData);
        }
    }
}

OSStatus StartQueueIfNeeded(MyData* myData)
{
    if(((myData->volume - g_volce) >= - EPSINON) && ((myData->volume - g_volce) <= EPSINON)){
        
    }
    else
    {
        myData->volume = g_volce;
        //设置音量
        AudioQueueSetParameter(myData->audioQueue, kAudioQueueParam_Volume, myData->volume);
    }
    
    OSStatus err = noErr;
    if (!myData->started)
    {		// start the queue if it has not been started already
        OSStatus result = AudioQueueSetParameter( myData->audioQueue, kAudioQueueParam_Volume, g_volce);
        //        if (result != noErr) {
        //            NSLog(@"kAudioQueueParam_Volume");
        //        }
        err = AudioQueuePrime(myData->audioQueue, 0, NULL);
        err = AudioQueueStart(myData->audioQueue, NULL);
        if (err)
        {
            perror("AudioQueueStart");
            myData->failed = true;
            NSLog(@"myData->failed1");
            return err;
        }
        myData->started = true;
        printf("started\n");
    }
    return err;
}

OSStatus MyEnqueueBuffer(MyData* myData)
{
    OSStatus err = noErr;
    myData->inuse[myData->fillBufferIndex] = true;		// set in use flag
    //	NSLog(@"*************************************************   \t%d\t%d \t%d", myData->inuse[0], myData->inuse[1], myData->inuse[2]);
    //	NSLog(@"myData->fillBufferIndex:%d", myData->fillBufferIndex);
    //	NSLog(@"myData->bytesFilled:%lu", myData->bytesFilled);
    //	NSLog(@"myData->packetsFilled:%lu",myData->packetsFilled);
    
    // enqueue buffer
    AudioQueueBufferRef fillBuf = myData->audioQueueBuffer[myData->fillBufferIndex];
    fillBuf->mAudioDataByteSize = myData->bytesFilled;
    err = AudioQueueEnqueueBuffer(myData->audioQueue, fillBuf, myData->packetsFilled, myData->packetDescs);
    if (err)
    {
        perror("AudioQueueEnqueueBuffer");
        myData->failed = true;
        NSLog(@"myData->failed 2");
        return err;
    }
    StartQueueIfNeeded(myData);
    return err;
}


void WaitForFreeBuffer(MyData* myData)
{
    if (++myData->fillBufferIndex >= kNumAQBufs)
    {
        myData->fillBufferIndex = 0;
        myData->bytesFilled = 0;		// reset bytes filled
        myData->packetsFilled = 0;		// reset packets filled
        AudioQueueReset(myData->audioQueue);
        OSStatus err = AudioQueueFlush(myData->audioQueue);
        myData->started = false;
        NSLog(@"AudioQueueFlush");
        usleep(100);
        return;
    }
    myData->bytesFilled = 0;		// reset bytes filled
    myData->packetsFilled = 0;		// reset packets filled
    
    // NSLog(@"WaitForFreeBuffer myData->fillBufferIndex = %d",myData->fillBufferIndex);
    //    AudioQueueBufferRef fillBuf = myData->audioQueueBuffer[myData->fillBufferIndex-1];
    //    AudioQueueFreeBuffer(myData->audioQueue, myData->audioQueueBuffer[myData->fillBufferIndex-1]);
    //    OSStatus err = AudioQueueAllocateBuffer(myData->audioQueue, kAQBufSize, &myData->audioQueueBuffer[myData->fillBufferIndex-1]);
    // wait until next buffer is not in use
    // pthread_mutex_lock(&myData->mutex);
    //    while (myData->inuse[myData->fillBufferIndex])
    //    {
    //         NSLog(@"WaitForFreeBuffer myData->fillBufferIndex = %d",myData->fillBufferIndex);
    //        AudioQueueBufferRef fillBuf = myData->audioQueueBuffer[myData->fillBufferIndex-1];
    //        AudioQueueFreeBuffer(myData->audioQueue, myData->audioQueueBuffer[myData->fillBufferIndex-1]);
    //        printf("... WAITING ...\n");
    //     //   pthread_cond_wait(&myData->cond, &myData->mutex);
    //    }
    //   // pthread_mutex_unlock(&myData->mutex);
    //    printf("<-unlock\n");
    usleep(1000);
}

int MyFindQueueBuffer(MyData* myData, AudioQueueBufferRef inBuffer)
{
    for (unsigned int i = 0; i < kNumAQBufs; ++i) {
        if (inBuffer == myData->audioQueueBuffer[i])
            return i;
    }
    return -1;
}


void MyAudioQueueOutputCallback(void*					inClientData,
                                AudioQueueRef			inAQ,
                                AudioQueueBufferRef		inBuffer)
{
    // this is called by the audio queue when it has finished decoding our data.
    // The buffer is now free to be reused.
    MyData* myData = (MyData*)inClientData;
    
    //	UInt32 running;
    //	UInt32 size;
    //	OSStatus err = AudioQueueGetProperty(inAQ, kAudioQueueProperty_IsRunning, &running, &size);
    //	NSLog(@" running:%lu, error: %ld", running, err);
    unsigned int bufIndex = MyFindQueueBuffer(myData, inBuffer);
    NSLog(@"MyAudioQueueOutputCallback,bufIndex = %d",bufIndex);
    // signal waiting thread that the buffer is free.
    //pthread_mutex_lock(&myData->mutex);
    myData->inuse[bufIndex] = false;
    //pthread_cond_signal(&myData->cond);
    //pthread_mutex_unlock(&myData->mutex);
}

void MyAudioQueueIsRunningCallback(		void*			inClientData,
                                   AudioQueueRef		inAQ,
                                   AudioQueuePropertyID	inID)
{
    MyData* myData = (MyData*)inClientData;
    
    UInt32 running;
    UInt32 size;
    OSStatus err = AudioQueueGetProperty(inAQ, kAudioQueueProperty_IsRunning, &running, &size);
    //  NSLog(@"kAudioQueueProperty_IsRunning = %d,running = %d",kAudioQueueProperty_IsRunning,(unsigned int)running);
    if (err != noErr)
    {
        perror("get kAudioQueueProperty_IsRunning");
        return;
    }
    if (!running) {
        pthread_mutex_lock(&myData->mutex);
        pthread_cond_signal(&myData->done);
        pthread_mutex_unlock(&myData->mutex);
    }
}

//http://mechenwei3.iteye.com/blog/1175543 audioQueue示意图

@implementation GDAudioDecoder
{
    NSTimer *resetAudioTimer;
    BOOL _stopAudio;
}

#pragma mark - init

-(id)init
{
    if (self = [super init])
    {
        myData = NULL;
        packetCount = 0;
        resetAudioTimer = nil;
        //		[self audioQueueOpen];
        audioQueueIsPaused = NO;
        //        resetAudioTimer = [NSTimer scheduledTimerWithTimeInterval:20 target:self selector:@selector(audioQueueRestart) userInfo:nil repeats:YES];
        // [self addHardKeyVolumeListener];
    }
    return self;
}

-(void)playWith:(char*)audioBuffer andBufferLen:(int)len
{
    @synchronized(self) {
        if (_stopAudio) {
            audioplayerErr = AudioFileStreamParseBytes(myData->audioFileStream, len, audioBuffer, 0);
            if (audioplayerErr)
            {
                printf("AudioFileStreamParseBytes");
            }
        }
        else
        {
            //NSLog(@"_stopAudio = %d",_stopAudio);
        }
    }
}

#pragma mark - audio play

-(void)audioQueueReset
{
    if (myData)
    {
        AudioQueueReset(myData->audioQueue);
    }
}

-(void)audioQueueRestart
{
    if (!packetCount) {
        return;
    }
    NSLog(@"audioQueueRestart");
    AudioQueueReset(myData->audioQueue);
    if (!audioQueueIsPaused)
    {
        [self audioQueuePlay];
        packetCount=0;
    }
}

-(BOOL)audioQueueOpen
{
    NSLog(@"audio queue open");
    if (myData == NULL) {
        // allocate a struct for storing our state
        myData = (MyData*)calloc(1, sizeof(MyData));
        myData->volume = 50.0f;
        // initialize a mutex and condition so that we can block on buffers in use.
        pthread_mutex_init(&myData->mutex, NULL);
        pthread_cond_init(&myData->cond, NULL);
        pthread_cond_init(&myData->done, NULL);
        // create an audio file stream parser
        audioplayerErr = AudioFileStreamOpen(myData, MyPropertyListenerProc, MyPacketsProc, kAudioFileAAC_ADTSType, &myData->audioFileStream);
        _stopAudio = YES;
        if (audioplayerErr)
        {
            printf("AudioFileStreamOpen err");
            return NO;
        }
    }
    return YES;
}


-(BOOL)audioQueueClose
{
    _stopAudio = NO;
    if (resetAudioTimer != nil) {
        [resetAudioTimer invalidate];
        resetAudioTimer = nil;
    }
    
    //    AudioQueueReset(myData->audioQueue);
    //此处内存泄露: AudioQueueFlush,AudioQueueStop
    OSStatus err = 0;
    if (myData != NULL) {
        err = AudioQueueFlush(myData->audioQueue);
        //	if (err)
        //	{
        //		perror("AudioQueueFlush\n");
        //		return NO;
        //	}
        //	NSLog(@"stopping");
        //2014-7-30
        err = AudioQueueStop(myData->audioQueue, true);
        if (err)
        {
            perror("AudioQueueStop\n");
            return NO;
        }
        usleep(10);
        AudioFileStreamClose(myData->audioFileStream);
        AudioQueueDispose(myData->audioQueue, false);
        myData->audioQueue=nil;
        myData->audioFileStream=nil;
        
        memset(&myData, 0, sizeof(myData));
        free(myData);
        myData =nil;
    }
    NSLog(@"audio queue close");
    //	printf("waiting until finished playing..\n");
    //	pthread_mutex_lock(&myData->mutex);
    //	pthread_cond_wait(&myData->done, &myData->mutex);
    //	pthread_mutex_unlock(&myData->mutex);
    
    //2014-7-30
    // err = AudioFileStreamClose(myData->audioFileStream);
    //	err = AudioQueueDispose(myData->audioQueue, false);
    //
    //    free(myData);
    //    myData = nil;
    return YES;
}

-(BOOL)audioQueuePause
{
    audioQueueIsPaused = YES;
    audioplayerErr = AudioQueuePause(myData->audioQueue);
    if (audioplayerErr)
    {
        printf("audioQueuePause");
        return NO;
    }
    return YES;
}

//这里的播放是指从暂停到播放
-(BOOL)audioQueuePlay
{
    audioQueueIsPaused = NO;
    audioplayerErr = AudioQueueStart(myData->audioQueue, NULL);
    if (audioplayerErr)
    {
        printf("audioQueuePlay ERROR");
        return NO;
    }
    return YES;
}

- (NSString *)nowTime
{
    NSDate *date = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *comps;
    comps = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit) fromDate:date];
    return [NSString stringWithFormat:@"%.4ld-%.2ld-%.2ld %.2ld:%.2ld:%.2ld",(long)[comps year],(long)[comps month],(long)[comps day],(long)[comps hour],(long)[comps minute],(long)[comps second]];
}


#pragma mark - dealloc

-(void)dealloc
{
    if (myData != NULL) {
    }
    NSLog(@"GDAudioDecoder");
}

@end
