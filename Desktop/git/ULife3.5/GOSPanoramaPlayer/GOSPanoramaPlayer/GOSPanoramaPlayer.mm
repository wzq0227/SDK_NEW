//
//  GOSPanoramaPlayer.m
//  GOSPanoramaPlayer
//
//  Created by zhuochuncai on 17/7/17.
//  Copyright © 2017年 Gospell. All rights reserved.
//

#import "GOSPanoramaPlayer.h"
#import <sys/time.h>

#include "commonFun.h"
#include "shader_utils.h"

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <OpenGLES/gltypes.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/EAGLDrawable.h>

#include <time.h>

#define GLM_FORCE_RADIANS
#include  "glm.hpp"
#include  "matrix_transform.hpp"
#include  "type_ptr.hpp"
#include "ogl.h"


@interface GOSPanoramaPlayer()
{
    
    CAEAGLLayer *_eaglLayer;
    EAGLContext *_mContext;
}
@end

int timeLoop=0;
float timeuse=0;

struct timeval start;
struct timeval end;

unsigned char* videoIn;
int disW=1280;
int disH=960;
int videoInW=1920;
int videoInH=1080;

int videoInCropW=1080;
int yuvSize=videoInW*videoInH*3/2;


int motionSig[3];
int clickSig=-1;
int autoRotSig;
my_Image *imgIn;
unsigned char*	yuvIn;

@implementation GOSPanoramaPlayer

+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

-(id)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
//        [self setupContext];
    }
    return self;
}


-(void)setupContext{

    self.contentScaleFactor = [[UIScreen mainScreen] scale];
    
    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
    
    eaglLayer.opaque = YES;
    eaglLayer.drawableProperties = @{ kEAGLDrawablePropertyRetainedBacking :[NSNumber numberWithBool:NO],
                                      kEAGLDrawablePropertyColorFormat : kEAGLColorFormatRGBA8};
//    self.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
//    self.drawableDepthFormat = GLKViewDrawableDepthFormat16;
//    self.drawableStencilFormat = GLKViewDrawableStencilFormat8;
//    self.drawableMultisample = GLKViewDrawableMultisample4X;

    _mContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!_mContext || ![EAGLContext setCurrentContext:_mContext] ) {
        return ;
    }
    self.context = _mContext;
    
    self.backgroundColor = [UIColor redColor];
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]))
    {
//        [self setupContext];
    }
    return self;
}

- (void)gosPanorama_updateDisplayWidth:(int)width height:(int)height{
    disW = width;
    disH = height;
}

- (void)gosPanorama_updateVideoWidth:(int)width height:(int)height{
    videoInW = width;
    videoInH = height;
}

/**
 更新视频显示模式
 */
- (void)gosPanorama_updateClickSignal{
    clickAction(_clickSig);
}


/**
 更新缩放、拖拽等手势信号
 */
- (void)gosPanorama_updateMotionSignal {
    float zoomTmp[3];
    zoomTmp[0] = _zoomSig0;
    zoomTmp[1]=_zoomSig1;
    zoomTmp[2]=_zoomSig2;
    motionAction(_touchStatus, _tx, _ty, zoomTmp, _clickDouble, _autoRotSig);
}



- (void)gosPanorama_initWithWidth:(int)W height:(int)H disWidth:(int)disWidth disHeight:(int)disHeight initialMode:(int)mode{
    
    videoInH = H;
    videoInW = W;
    
    disW =  disWidth;
    disH =  disHeight;
    
    oglInit(videoInW,videoInH,mode);
}

- (void)gosPanorama_stepWithTouchStatus:(int) touchStatus
                                     tx:(int) tx
                                     ty:(int) ty
                               clickSig:(int) clickSig
                          autoRotSignal:(int) autoRotSignal
                               zoomSig0:(float) zoomSig0
                               zoomSig1:(float) zoomSig1
                               zoomSig2:(float) zoomSig2
                                 disold:(int) disold
                                yuvData:(UInt8 *)yuvData
                            clickDouble:(int)clickDouble
{
//    if(timeLoop==0){
//
//        gettimeofday(&start,0);
//        timestart = 1000000 * start.tv_sec + start.tv_usec;
//    }
    timeLoop++;
    motionSig[0]=touchStatus;
    motionSig[1]=tx;
    motionSig[2]=ty;
    autoRotSig=autoRotSignal;
   
    float zoomTmp[3];
    zoomTmp[0]=zoomSig0;
    zoomTmp[1]=zoomSig1;
    zoomTmp[2]=zoomSig2;
    //	 for yuv yv12
    
    //self.delegateView
    oglRun(yuvData, self.delegateView,videoInW, videoInH,disW,disH, motionSig, clickSig,autoRotSig,zoomTmp,clickDouble);


    //for bmps
    //oglRun(imgIn->imageData, imgIn->width, imgIn->height,disW,disH, motionSig, clickSig,autoRotSig,zoomTmp);
}


- (void)gosPanorama_updateWithYUVData:(UInt8 *)yuvData{
    [self gosPanorama_stepWithTouchStatus:_touchStatus tx:_tx ty:_ty clickSig:_clickSig autoRotSignal:_autoRotSig zoomSig0:_zoomSig0 zoomSig1:_zoomSig1 zoomSig2:_zoomSig2 disold:0 yuvData:yuvData clickDouble:_clickDouble];
}


@end
