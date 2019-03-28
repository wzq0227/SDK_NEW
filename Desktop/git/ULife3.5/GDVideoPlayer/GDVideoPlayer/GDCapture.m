//
//  THCapture.m
//  ScreenCaptureViewTest
//
//  Created by wayne li on 11-8-24.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "GDCapture.h"
#import "GDVideoStateInfo.h"

//static NSString* const kAudioName = @"audio.wav";
static CMTime g_timer;
@interface GDCapture()
{
    dispatch_queue_t _queue;
    BOOL _isSavePhoto;
    CMTime _startTimer;
}

@property(nonatomic,strong)AVAssetExportSession* assetExport;
//配置录制环境
-(BOOL) setUpWriterWithWidth:(int)width height:(int)height;
//清理录制环境
- (void)cleanupWriter;
//完成录制工作
- (void)completeRecordingSession;
@property(nonatomic,copy)NSString *saveVideoPath;
@property(nonatomic,copy)NSString *tempFilePath;
@property(nonatomic,copy)NSString *audioFilePath;
- (void)mergeVideo:(NSString *)videoPath andAudio:(NSString *)audioPath andTarget:(id)target andAction:(SEL)action;
@end

@implementation GDCapture

-(void)setRecordTarget:(id)target callback:(SEL)callback
{
	_target = target;
	_callback = callback;
}

-(void)videoAndAudioSynthetic:(id)target callback:(SEL)callback andSavePhoto:(BOOL)isSavePhoto andPath:(NSString *)Path
{
     _startTimer = g_timer;
    _isSavePhoto = isSavePhoto;
    if (_isSavePhoto) {
        self.saveVideoPath = [Path copy];
    }
    _target = target;
    _callback = callback;
    if (_queue == nil) {
        _queue = dispatch_queue_create("GDCapture", DISPATCH_QUEUE_CONCURRENT);
    }
    [self mergeVideo:[self tempFilePath] andAudio:[self audioFilePath] andTarget:_target andAction:_callback];
}

- (void)dealloc
{
    NSLog(@"________GDCapture_______dealloc");
	_target = nil;
	_callback = nil;
    if (_assetExport != nil) {

        _assetExport = nil;
    }
	[self cleanupWriter];

}

#pragma mark -
#pragma mark CustomMethod
- (BOOL)startRecordingWithAudioEnabled:(BOOL)enabled andSavePhoto:(BOOL)isSavePhoto width:(int)width height:(int)height andPath:(NSString *)Path
{
    BOOL result = NO;
    if (! _recording && !_isBusy)
    {
        result = [self setUpWriterWithWidth:width height:height];
        if (result)
        {
            g_timer  = kCMTimeZero;
            _startTimer = kCMTimeZero;
            _queue = dispatch_queue_create("GDCapture", DISPATCH_QUEUE_CONCURRENT);
            startedAt = [NSDate date];
            _recording = true;
            _writing = false;
            _isBusy = YES;
			_audioIsOn = enabled;
			_assetExport = nil;
            _startFlag = YES;
            _isSavePhoto = isSavePhoto;
            if (_isSavePhoto) {
                
            }
            else
            {
                 self.saveVideoPath = [Path copy];
            }
           
        }
    }
	return result;
}

- (void)stopRecording
{
    if (_recording)
	{
		NSLog(@"stopRecording");
        _recording = false;
        [self completeRecordingSession];
        [self cleanupWriter];
    }
}

//录像
- (void)drawFrame:(CGImageRef)cgImage
{
    if (!_writing) {
        _writing = true;
		NSLog(@"录像 写入 开始");
			if (_recording) {
				float millisElapsed = [[NSDate date] timeIntervalSinceDate:startedAt] * 1000.0;
				CMTime time = CMTimeMake((int)millisElapsed, 1000);
                Float64 duration = CMTimeGetSeconds(time);
                NSLog(@"视频时长 %f\n",duration);
                if (_startFlag) {
                    _startTimer = time;
                    g_timer = time;
                    _startFlag = NO;
                }
                
				//write
				if (![videoWriterInput isReadyForMoreMediaData])
				{
					NSLog(@"Not ready for video data");
				}
				else
				{
					CVPixelBufferRef pixelBuffer = NULL;
                    
                    CFDataRef image = CGDataProviderCopyData(CGImageGetDataProvider(cgImage));
					int status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, avAdaptor.pixelBufferPool, &pixelBuffer);
					if(status != 0)
					{
						//could not get a buffer from the pool
						NSLog(@"Error creating pixel buffer:  status=%d", status);
					}
                    
					// set image data into pixel buffer
					CVPixelBufferLockBaseAddress( pixelBuffer, 0 );
					uint8_t* destPixels = CVPixelBufferGetBaseAddress(pixelBuffer);
                    
					//XXX:  will work if the pixel buffer is contiguous and has the same bytesPerRow as the input data
					//NSLog(@"CFDataGetLength(image): %ld", CFDataGetLength(image));
                    
					CFDataGetBytes(image, CFRangeMake(0, CFDataGetLength(image)), destPixels);
					if(status == 0)
					{
						BOOL success = [avAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:time];
						if (!success)
							NSLog(@"Warning:  Unable to write buffer to video");
					}
					
					//clean up
					CVPixelBufferUnlockBaseAddress( pixelBuffer,0);
					CVPixelBufferRelease( pixelBuffer);
                   // CVBufferRelease(pixelBuffer);
					CFRelease(image);
				}
			}
			_writing = false;
			NSLog(@"录像 写入 结束");
    }
	else
	{
		NSLog(@"写入失败");
	}
}

-(BOOL) setUpWriterWithWidth:(int)width height:(int)height
{
	CGSize size = CGSizeMake(width, height);
    
    //Clear Old TempFile
	NSError  *error = nil;
    NSString *filePath=[self tempFilePath];
    NSFileManager* fileManager = [NSFileManager defaultManager];
	if ([fileManager fileExistsAtPath:filePath])
    {
		if ([fileManager removeItemAtPath:filePath error:&error] == NO)
        {
			NSLog(@"Could not delete old recording file at path:  %@", filePath);
            return NO;
		}
	}
    
    //Configure videoWriter
    NSURL   *fileUrl=[NSURL fileURLWithPath:filePath];
	videoWriter = [[AVAssetWriter alloc] initWithURL:fileUrl fileType:AVFileTypeMPEG4 error:&error];
	NSParameterAssert(videoWriter);
	
	//Configure videoWriterInput
	NSDictionary* videoCompressionProps = [NSDictionary dictionaryWithObjectsAndKeys:
										   [NSNumber numberWithDouble:1024*1024], AVVideoAverageBitRateKey,
//										   1.0, AVVideoQualityKey,
										   nil ];
	
	NSDictionary* videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
								   AVVideoCodecH264, AVVideoCodecKey,
								   [NSNumber numberWithInt:size.width], AVVideoWidthKey,
								   [NSNumber numberWithInt:size.height], AVVideoHeightKey,
								   videoCompressionProps, AVVideoCompressionPropertiesKey,
								   nil];
	
	videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings] ;
	
	NSParameterAssert(videoWriterInput);
	videoWriterInput.expectsMediaDataInRealTime = YES;
	NSDictionary* bufferAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey, nil];
	
	avAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput sourcePixelBufferAttributes:bufferAttributes];
	
	//add input
	[videoWriter addInput:videoWriterInput];
	[videoWriter startWriting];
	[videoWriter startSessionAtSourceTime:CMTimeMake(0, 1000)];
    
    //create context
    if (context== NULL)
    {
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        context = CGBitmapContextCreate (NULL,
                                         size.width,
                                         size.height,
                                         8,//bits per component
                                         size.width * 4,
                                         colorSpace,
                                         kCGImageAlphaNoneSkipFirst);
        CGColorSpaceRelease(colorSpace);
        CGContextSetAllowsAntialiasing(context,NO);
        CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, size.height);
        CGContextConcatCTM(context, flipVertical);
    }
    
    if (context== NULL)
    {
		fprintf (stderr, "Context not created!");
        return NO;
	}
	return YES;
}

- (void) completeRecordingSession {
    
	[videoWriterInput markAsFinished];
	// Wait for the video
	int status = videoWriter.status;
	while (status == AVAssetWriterStatusUnknown)
    {
		NSLog(@"Waiting...");
		[NSThread sleepForTimeInterval:0.5f];
		status = videoWriter.status;
	}
	
    BOOL success = [videoWriter finishWriting];
    if (!success)
    {
        NSLog(@"finishWriting returned NO");
        if (_target && _callback && [_target respondsToSelector:_callback])
		{
			NSError* error = [NSError errorWithDomain:@"录像失败" code:-1 userInfo:nil];
            [_target performSelector:_callback withObject:_saveVideoPath withObject:error];
        }
		_isBusy = NO;
        return ;
    }
    NSLog(@"Completed recording, file is stored at:  %@", [self tempFilePath]);
    
	//合成
	if (_audioIsOn)
	{
		[self mergeVideo:[self tempFilePath] andAudio:[self audioFilePath] andTarget:_target andAction:_callback];
	}
	else
	{
		[self mergeVideo:[self tempFilePath] andAudio:nil andTarget:_target andAction:_callback];
	}
}


- (void)mergeVideo:(NSString *)videoPath andAudio:(NSString *)audioPath andTarget:(id)target andAction:(SEL)action
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:videoPath]) //如果不存
    {
        NSError* error = [[NSError alloc] initWithDomain:@"视频文件不存在" code:-1 userInfo:nil];
        [_target performSelector:_callback withObject:_saveVideoPath withObject:error];
        return;
    }
    
    if (videoPath == nil){
        NSError* error = [[NSError alloc] initWithDomain:@"视频文件为空" code:-1 userInfo:nil];
        [_target performSelector:_callback withObject:_saveVideoPath withObject:error];
        return;
    }
	NSURL *videoUrl=[NSURL fileURLWithPath:videoPath];
	if (audioPath)
	{
        dispatch_async(_queue,^{
            AVURLAsset* videoAsset = [[AVURLAsset alloc]initWithURL:videoUrl options:nil];
            CMTime videoassetTime = [videoAsset duration];
            Float64 videoduration = CMTimeGetSeconds(videoassetTime);
            CMTime trackDuration = videoAsset.duration;
            NSLog(@"视频时长 %f\n",videoduration);
            if (videoduration <= 3.0) {
                NSError* error = [[NSError alloc] initWithDomain:@"录制时间太短,无法生成录像" code:-1 userInfo:nil];
                [_target performSelector:_callback withObject:_saveVideoPath withObject:error];
                return;
            }

            NSURL *audioUrl=[NSURL fileURLWithPath:audioPath];
            AVURLAsset* audioAsset = [[AVURLAsset alloc]initWithURL:audioUrl options:nil];
            CMTime assetTime = [audioAsset duration];
            CMTime startTime = CMTimeMakeWithSeconds(0, 1);
            
            Float64 duration = CMTimeGetSeconds(assetTime);
            NSLog(@"语音时长 %f\n",duration);
            if (duration <= 3.0) {
                NSError* error = [[NSError alloc] initWithDomain:@"录制时间太短,无法生成录像" code:-1 userInfo:nil];
                [_target performSelector:_callback withObject:_saveVideoPath withObject:error];
                return;
            }
            
            //混合音乐
            AVMutableComposition* mixComposition = [AVMutableComposition composition];
            
            AVMutableCompositionTrack *compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                                           preferredTrackID:kCMPersistentTrackID_Invalid];
            
            BOOL Videoret = [compositionVideoTrack insertTimeRange:CMTimeRangeMake(_startTimer, videoassetTime)
                                                           ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
                                                            atTime:kCMTimeZero error:nil];
            
            
            AVMutableCompositionTrack *compositionAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                                           preferredTrackID:kCMPersistentTrackID_Invalid];
            CMTime startTimeTrack = startTime;
            CMTime trackDurationTrack = trackDuration;
            CMTimeRange tRange = CMTimeRangeMake(startTimeTrack, trackDurationTrack);
            
            AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
            //Set Volume
            AVMutableAudioMixInputParameters *trackMix = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:compositionAudioTrack];
            [trackMix setTrackID:compositionAudioTrack.trackID];
            [trackMix setVolume:30.0f atTime:startTime];
            [trackMix setVolumeRampFromStartVolume:g_volce toEndVolume:g_volce
                                         timeRange:tRange];
            audioMix.inputParameters = @[trackMix];
           
            
            BOOL Audioret = [compositionAudioTrack insertTimeRange:CMTimeRangeMake(_startTimer, videoassetTime)
                                                           ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0]
                                                            atTime:kCMTimeZero error:nil];
            NSLog(@"Videoret = %d,Audioret = %d",Videoret,Audioret);
            
            NSURL  *exportUrl = [NSURL fileURLWithPath:[self exportFilePath]];
            if ([[NSFileManager defaultManager] fileExistsAtPath:[self exportFilePath]])
            {
                [[NSFileManager defaultManager] removeItemAtPath:[self exportFilePath] error:nil];
            }
            
            _assetExport = [[AVAssetExportSession alloc]initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
            //保存混合后的文件的过程
            _assetExport.outputFileType = AVFileTypeMPEG4;//@"com.apple.quicktime-movie";
            //_assetExport.outputFileType = @"com.apple.quicktime-movie";
            _assetExport.outputURL = exportUrl;
            _assetExport.shouldOptimizeForNetworkUse = YES;
            _assetExport.audioMix = audioMix;
            
            NSString *exportPath = [self exportFilePath];
            NSLog(@"exportPath = %@",[self exportFilePath]);

            __block typeof(self) weakSelf = self;
            if (_queue == nil) {
                _queue = dispatch_queue_create("GDCapture", DISPATCH_QUEUE_CONCURRENT);
            }
            NSLog(@"file type %@", [_assetExport supportedFileTypes]);
            NSLog(@"_assetExport = %p,exportUrl = %p",_assetExport,exportUrl);
        
            [weakSelf.assetExport exportAsynchronouslyWithCompletionHandler:^(void){
                NSLog(@"exportAsynchronouslyWithCompletionHandler ");
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"weakSelf.assetExport.status = %d",weakSelf.assetExport.status);
                    if(weakSelf.assetExport.status == AVAssetExportSessionStatusCompleted)
                    {
                        NSFileManager *fileManager = [NSFileManager defaultManager];
                        if([fileManager fileExistsAtPath:exportPath]) //如果不存
                        {
                            if (_isSavePhoto) {
                                if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(exportPath))
                                {
                                    NSLog(@"完成了,   保存文件至相册: %@", exportPath);
                                    UISaveVideoAtPathToSavedPhotosAlbum(exportPath, target, action, nil);
                                    [weakSelf postAction:action toTarget:target withObject:nil withError:nil];
                                }
                                else if ([target respondsToSelector:action])
                                {
                                    NSLog(@"完成了, 保存失败");
                                    NSError* err = [[NSError alloc] initWithDomain:@"filed to save." code:-1 userInfo:nil];
                                    [weakSelf postAction:action toTarget:target withObject:nil withError:err];
                                }
                            }
                            else
                            {
                                NSError *error;
                                if([fileManager copyItemAtPath:exportPath toPath:_saveVideoPath error:&error])
                                {
                                    NSLog(@"文件保存成功");
                                    [_target performSelector:_callback withObject:_saveVideoPath withObject:nil];
                                    [fileManager removeItemAtPath:exportPath error:&error];
                                    NSString *filePath=[weakSelf tempFilePath];
                                    [fileManager removeItemAtPath:filePath error:&error];
                                    
                                }
                                else if ([target respondsToSelector:action])
                                {
                                    NSError* error = [[NSError alloc] initWithDomain:@"filed save fail" code:-1 userInfo:nil];
                                    [_target performSelector:_callback withObject:_saveVideoPath withObject:error];

                                }

                            }
                       }
                        _isBusy = NO;
                    }
                    else
                    {
                        if (_isSavePhoto) {
                            if ([target respondsToSelector:action])
                            {
                                NSLog(@"完成了, 保存失败");
                                NSError* err = [[NSError alloc] initWithDomain:@"filed to save." code:-1 userInfo:nil];
                                [weakSelf postAction:action toTarget:target withObject:nil withError:err];
                            }
                        }
                        else
                        {
                            if ([target respondsToSelector:action])
                            {
                                NSString *errorStr = [[weakSelf.assetExport error] localizedDescription];
                                NSError* error = [[NSError alloc] initWithDomain:errorStr code:-1 userInfo:nil];
                                NSLog(@"errorStr = %@",error);
                                [_target performSelector:_callback withObject:_saveVideoPath withObject:error];
                            }
                        }
                    }
                });
                
            }];
        });
    }
	else
    {
        if (!_isSavePhoto) {
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if([fileManager fileExistsAtPath:videoPath]) //如果不存
            {
                NSError *error;
                if([fileManager copyItemAtPath:videoPath toPath:_saveVideoPath error:&error])
                {
                    [_target performSelector:_callback withObject:_saveVideoPath withObject:nil];
                }
                else if ([target respondsToSelector:action])
                {
                    NSError* error = [[NSError alloc] initWithDomain:@"filed save fail" code:-1 userInfo:nil];
                    [_target performSelector:_callback withObject:_saveVideoPath withObject:error];
                }
            }
        }
        else
        {
            if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(videoPath))
            {
                NSLog(@"完成了,   保存文件至相册: %@", videoPath);
                UISaveVideoAtPathToSavedPhotosAlbum(videoPath, target, action, nil);
                [self postAction:action toTarget:target withObject:nil withError:nil];
            }
            else if ([target respondsToSelector:action])
            {
                NSLog(@"完成了,   保存失败");
                NSError* err = [[NSError alloc] initWithDomain:@"filed to save." code:-1 userInfo:nil];
                [self postAction:action toTarget:target withObject:nil withError:err];

            }
        }

        _isBusy = NO;
    }
}

- (void) cleanupWriter {
    NSLog(@"cleanupWriter");
    if (avAdaptor != nil) {

        avAdaptor = nil;
    }
    
    if (videoWriterInput != nil) {

        videoWriterInput = nil;
    }

    if (videoWriter != nil) {

        videoWriter = nil;
    }
   
    if (startedAt != nil) {

        startedAt = nil;
    }
    
    if (context != nil) {
        CGContextRelease(context);
        context=NULL;
    }
    
    if (_queue != nil) {
        _queue = nil;
    }
}

- (NSString*)tempFilePath
{
    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:VideoFile];
    //return [filePath autorelease];
    return filePath;
}

- (NSString*)audioFilePath
{
    NSString *docDir = NSTemporaryDirectory();
    NSString* tempRecorderPath = [docDir stringByAppendingPathComponent:AudioFile];
    //return [tempRecorderPath autorelease];
    return tempRecorderPath;
}

-(NSString *)exportFilePath
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"yyyy-MM-dd_HH:mm:ss"];
    NSString *dateTime = [formatter stringFromDate:[NSDate date]];
    NSString* videoName = [NSString stringWithFormat:@"%@.mp4",dateTime];
    NSString *exportPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:videoName];
    return exportPath;
}

-(void)postAction:(SEL)action toTarget:(id)target withObject:(id)object1 withError:(NSError*)err
{
    [target performSelector:action withObject:object1 withObject:err];
}


#pragma mark -  AUDIO RECORD


//NSString *audiopath = [[NSBundle mainBundle]pathForResource:@"SIMPLE2" ofType:@"m4a"];
//NSString *videopath = [[NSBundle mainBundle]pathForResource:@"video" ofType:@"mov"];
//AVURLAsset* audioAsset = [[AVURLAsset alloc]initWithURL:[NSURL fileURLWithPath:audiopath] options:nil];
//AVURLAsset* videoAsset = [[AVURLAsset alloc]initWithURL:[NSURL fileURLWithPath:videopath] options:nil];

//AVMutableComposition* mixComposition = [AVMutableComposition composition];
//AVMutableCompositionTrack *compositionCommentaryTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio
//                                                                                    preferredTrackID:kCMPersistentTrackID_Invalid];
//
//[compositionCommentaryTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration)
//                                    ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0]
//                                     atTime:kCMTimeZero error:nil];
//AVMutableCompositionTrack *compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
//                                                                               preferredTrackID:kCMPersistentTrackID_Invalid];
//[compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration)
//                               ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
//                                atTime:kCMTimeZero error:nil];
//
//AVAssetExportSession* _assetExport = [[AVAssetExportSession alloc] initWithAsset:mixComposition
//                                                                      presetName:AVAssetExportPresetPassthrough];
//NSString* videoName = @"RongTian.mov";
//NSString *exportPath = [NSTemporaryDirectory() stringByAppendingPathComponent:videoName];
//NSURL    *exportUrl = [NSURL fileURLWithPath:exportPath];
//if ([[NSFileManager defaultManager] fileExistsAtPath:exportPath])
//{
//    [[NSFileManager defaultManager] removeItemAtPath:exportPath error:nil];
//}
//_assetExport.outputFileType = @"com.apple.quicktime-movie";
//_assetExport.outputURL = exportUrl;
//_assetExport.shouldOptimizeForNetworkUse = YES;

//[_assetExport exportAsynchronouslyWithCompletionHandler:
// ^(void ) {
//     
// }
// ];

@end
