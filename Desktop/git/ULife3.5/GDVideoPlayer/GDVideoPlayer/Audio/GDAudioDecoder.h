////
////  UlifePlayerAudioDecoder.h
////  GVAP iPhone
////
////  Created by  on 12-4-11.
////  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
////

#import <Foundation/Foundation.h>
#import <stdio.h>
#import <string.h>
#import <netdb.h>
#import <netinet/in.h>
#import <unistd.h>
#import <pthread.h>
#import <AudioToolbox/AudioToolbox.h>
#import <arpa/inet.h>
#import <sys/types.h>
//#import <sys/socket.h>

#import "WriteTxt.h"

#pragma mark for aac play
//#define PRINTERROR(LABEL)	printf("%s err %4.4s %d\n", LABEL, &err, err)
//int port = 51515;

#define		kNumAQBufs			16
#define		kAQBufSize			2048
#define		kAQMaxPacketDescs	512

struct MyDataStruct
{
    AudioFileStreamID audioFileStream;	// the audio file stream parser
    
    AudioQueueRef audioQueue;								// the audio queue
    AudioQueueBufferRef audioQueueBuffer[kAQBufSize];		// audio queue buffers
    
    AudioStreamPacketDescription packetDescs[kAQMaxPacketDescs];	// packet descriptions for enqueuing audio
    
    unsigned int fillBufferIndex;	// the index of the audioQueueBuffer that is being filled
    size_t bytesFilled;				// how many bytes have been filled
    size_t packetsFilled;			// how many packets have been filled
    float volume;
    
    bool inuse[kNumAQBufs];			// flags to indicate that a buffer is still in use
    bool started;					// flag to indicate that the queue has been started
    bool failed;					// flag to indicate an error occurred
    
    unsigned int bitRate;
    pthread_mutex_t mutex2;
    pthread_mutex_t mutex;			// a mutex to protect the inuse flags
    pthread_cond_t cond;			// a condition varable for handling the inuse flags
    pthread_cond_t done;			// a condition varable for handling the inuse flags
};
typedef struct MyDataStruct MyData;


@interface GDAudioDecoder : NSObject
{
    OSStatus audioplayerErr;
    MyData* myData;
    BOOL audioQueueIsPaused;
    int packetCount;
    
    
    WriteTxt* _writer;
}
-(void)playWith:(char*)audioBuffer andBufferLen:(int)len;
-(void)audioQueueReset;
-(BOOL)audioQueueOpen;
-(BOOL)audioQueuePause;
-(BOOL)audioQueuePlay;
-(BOOL)audioQueueClose;


void MyAudioQueueOutputCallback(void* inClientData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer);
void MyAudioQueueIsRunningCallback(void *inUserData, AudioQueueRef inAQ, AudioQueuePropertyID inID);

void MyPropertyListenerProc(void *							inClientData,
                            AudioFileStreamID				inAudioFileStream,
                            AudioFileStreamPropertyID		inPropertyID,
                            UInt32 *						ioFlags);

void MyPacketsProc(void *						inClientData,
                   UInt32						inNumberBytes,
                   UInt32						inNumberPackets,
                   const void *					inInputData,
                   AudioStreamPacketDescription	*inPacketDescriptions);

OSStatus	MyEnqueueBuffer(MyData* myData);
void		WaitForFreeBuffer(MyData* myData);
OSStatus	StartQueueIfNeeded(MyData* myData);
int			MyFindQueueBuffer(MyData* myData, AudioQueueBufferRef inBuffer);


@end
