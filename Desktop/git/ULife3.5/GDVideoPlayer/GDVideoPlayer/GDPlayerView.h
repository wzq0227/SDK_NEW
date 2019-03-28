//
//  OVWifiView.h
//  OVwifi
//
//  Created by HE BIAO on 3/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

#define screen_width [UIScreen mainScreen].bounds.size.width
#define screen_height [UIScreen mainScreen].bounds.size.height


typedef enum {
    
    kxMovieErrorNone,
    kxMovieErrorOpenFile,
    kxMovieErrorStreamInfoNotFound,
    kxMovieErrorStreamNotFound,
    kxMovieErrorCodecNotFound,
    kxMovieErrorOpenCodec,
    kxMovieErrorAllocateFrame,
    kxMovieErroSetupScaler,
    kxMovieErroReSampler,
    kxMovieErroUnsupported,
    
} kxMovieError;

typedef enum {
    
    KxMovieFrameTypeAudio,
    KxMovieFrameTypeVideo,
    KxMovieFrameTypeArtwork,
    KxMovieFrameTypeSubtitle,
    
} KxMovieFrameType;

typedef enum {
    
    KxVideoFrameFormatRGB,
    KxVideoFrameFormatYUV,
    
} KxVideoFrameFormat;

@interface KxMovieFrame : NSObject
@property (readwrite, nonatomic) KxMovieFrameType type;
@property (readwrite, nonatomic) CGFloat position;
@property (readwrite, nonatomic) CGFloat duration;
@end

@interface KxAudioFrame : KxMovieFrame
@property (readwrite, nonatomic, strong) NSData *samples;
@end

@interface KxVideoFrame : KxMovieFrame
@property (readwrite, nonatomic) KxVideoFrameFormat format;
@property (readwrite, nonatomic) NSUInteger width;
@property (readwrite, nonatomic) NSUInteger height;
@end

@interface KxVideoFrameRGB : KxVideoFrame
@property (readwrite, nonatomic) NSUInteger linesize;
@property (readwrite, nonatomic, strong) NSData *rgb;
- (UIImage *) asImage;
@end

@interface KxVideoFrameYUV : KxVideoFrame
@property (readwrite, nonatomic, strong) NSData *luma;
@property (readwrite, nonatomic, strong) NSData *chromaB;
@property (readwrite, nonatomic, strong) NSData *chromaR;
@end


@interface GDPlayerView : UIView<UIGestureRecognizerDelegate>
{
 @private	
	/* The pixel dimensions of the backbuffer */
    GLint decFrameWidth,decFrameHeight;
    GLint texWidth,texHeight;
    GLint surfaceWidth,surfaceHeight;
    
    GLint viewmode; //0:orisize(if framesize > surface, then same as mode2), 1:fullscreen-scale, 2:max-sameratio
    
	EAGLContext *context;
	
	/* OpenGL names for the renderbuffer and framebuffers used to render to this view */
	GLuint viewRenderbuffer, viewFramebuffer;
	
	/* OpenGL name for the depth buffer that is attached to viewFramebuffer, if it exists (0 if it does not exist) */
	GLuint depthRenderbuffer;
    GLfloat texcoords[8];
    GLfloat texvertices[8];
	
	/* OpenGL name for the sprite texture */
	GLuint texture_id;
    
    NSTimer *animationTimer;
   
    
    CGPoint originalLocation;
	CGPoint lastDragPoint;
	
    CGRect screen;
    float scrollX;
    float scrollHeight;
    float rotation;
    float lastScale;

    //改成捏合手势
    UIPinchGestureRecognizer *pinchRecognizer;
    
    //当前放大比例，最大是4x，最小是1
    CGFloat currentScale;
    

    UITapGestureRecognizer * doubleTapRecognizer;
	UIPanGestureRecognizer *panRecognizer;
    UIView *setScaleView;
    IBOutlet UIToolbar *toolBar;
    IBOutlet UIBarItem *rotateItem;
    IBOutlet UIBarItem *sendItem;
	
	NSLock* _lock;
	BOOL retinaDevice;
}

@property (nonatomic, strong) CAEAGLLayer *eaglLayer;
@property(nonatomic, assign)BOOL isDragging;
@property(nonatomic,assign)BOOL isdoubleScale;

-(BOOL)playViewSetup;
- (void)drawVideo:(void*)data;
- (void)setupView:(int)width setHeight:(int)height;
- (void)startView;

- (void)configViewSize;

- (id) initWithFrame:(CGRect)frame;

- (void) render: (KxVideoFrame *) frame;

/**
 暂停显示图像，用黑色填充
 */
- (void)setRenderStatePause:(BOOL)pause;
@end
