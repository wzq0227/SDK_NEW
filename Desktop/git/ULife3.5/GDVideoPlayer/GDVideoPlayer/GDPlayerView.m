//
//  OVWifiView.m
//  OVwifi
//
//  Created by HE BIAO on 3/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>
#import <SystemConfiguration/CaptiveNetwork.h>

#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>

#import "GDPlayerView.h"
//#import "GDFfmpeg.h"

#define isRetina YES





@implementation KxMovieFrame
@end

@implementation KxAudioFrame
- (KxMovieFrameType) type { return KxMovieFrameTypeAudio; }
@end

@implementation KxVideoFrame
- (KxMovieFrameType) type { return KxMovieFrameTypeVideo; }
@end

@implementation KxVideoFrameRGB
- (KxVideoFrameFormat) format { return KxVideoFrameFormatRGB; }
- (UIImage *) asImage
{
    UIImage *image = nil;
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)(_rgb));
    if (provider) {
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        if (colorSpace) {
            CGImageRef imageRef = CGImageCreate(self.width,
                                                self.height,
                                                8,
                                                24,
                                                self.linesize,
                                                colorSpace,
                                                kCGBitmapByteOrderDefault,
                                                provider,
                                                NULL,
                                                YES, // NO
                                                kCGRenderingIntentDefault);
            
            if (imageRef) {
                image = [UIImage imageWithCGImage:imageRef];
                CGImageRelease(imageRef);
            }
            CGColorSpaceRelease(colorSpace);
        }
        CGDataProviderRelease(provider);
    }
    
    return image;
}
@end

@implementation KxVideoFrameYUV
- (KxVideoFrameFormat) format { return KxVideoFrameFormatYUV; }
@end


//////////////////////////////////////////////////////////

#pragma mark - shaders

#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)

NSString *const vertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec2 texcoord;
 uniform mat4 modelViewProjectionMatrix;
 varying vec2 v_texcoord;
 
 void main()
 {
     gl_Position = modelViewProjectionMatrix * position;
     v_texcoord = texcoord.xy;
 }
 );

NSString *const rgbFragmentShaderString = SHADER_STRING
(
 varying highp vec2 v_texcoord;
 uniform sampler2D s_texture;
 
 void main()
 {
     gl_FragColor = texture2D(s_texture, v_texcoord);
 }
 );

NSString *const yuvFragmentShaderString = SHADER_STRING
(
 varying highp vec2 v_texcoord;
 uniform sampler2D s_texture_y;
 uniform sampler2D s_texture_u;
 uniform sampler2D s_texture_v;
 
 void main()
 {
     highp float y = texture2D(s_texture_y, v_texcoord).r;
     highp float u = texture2D(s_texture_u, v_texcoord).r - 0.5;
     highp float v = texture2D(s_texture_v, v_texcoord).r - 0.5;
     
     highp float r = y +             1.402 * v;
     highp float g = y - 0.344 * u - 0.714 * v;
     highp float b = y + 1.772 * u;
     
     gl_FragColor = vec4(r,g,b,1.0);
 }
 );

static BOOL validateProgram(GLuint prog)
{
    GLint status;
    
    glValidateProgram(prog);
    
#ifdef DEBUG
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == GL_FALSE) {
        NSLog(@"Failed to validate program %d", prog);
        return NO;
    }
    
    return YES;
}

static GLuint compileShader(GLenum type, NSString *shaderString)
{
    GLint status;
    const GLchar *sources = (GLchar *)shaderString.UTF8String;
    
    GLuint shader = glCreateShader(type);
    if (shader == 0 || shader == GL_INVALID_ENUM) {
        NSLog(@"Failed to create shader %d", type);
        return 0;
    }
    
    glShaderSource(shader, 1, &sources, NULL);
    glCompileShader(shader);
    
#ifdef DEBUG
    GLint logLength;
    glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(shader, GL_COMPILE_STATUS, &status);
    if (status == GL_FALSE) {
        glDeleteShader(shader);
        NSLog(@"Failed to compile shader:\n");
        return 0;
    }
    
    return shader;
}

static void mat4f_LoadOrtho(float left, float right, float bottom, float top, float near, float far, float* mout)
{
    float r_l = right - left;
    float t_b = top - bottom;
    float f_n = far - near;
    float tx = - (right + left) / (right - left);
    float ty = - (top + bottom) / (top - bottom);
    float tz = - (far + near) / (far - near);
    
    mout[0] = 2.0f / r_l;
    mout[1] = 0.0f;
    mout[2] = 0.0f;
    mout[3] = 0.0f;
    
    mout[4] = 0.0f;
    mout[5] = 2.0f / t_b;
    mout[6] = 0.0f;
    mout[7] = 0.0f;
    
    mout[8] = 0.0f;
    mout[9] = 0.0f;
    mout[10] = -2.0f / f_n;
    mout[11] = 0.0f;
    
    mout[12] = tx;
    mout[13] = ty;
    mout[14] = tz;
    mout[15] = 1.0f;
}

//////////////////////////////////////////////////////////

#pragma mark - frame renderers

@protocol KxMovieGLRenderer
- (BOOL) isValid;
- (NSString *) fragmentShader;
- (void) resolveUniforms: (GLuint) program;
- (void) setFrame: (KxVideoFrame *) frame;
- (BOOL) prepareRender;
@end

@interface KxMovieGLRenderer_RGB : NSObject<KxMovieGLRenderer> {
    
    GLint _uniformSampler;
    GLuint _texture;
}
@end

@implementation KxMovieGLRenderer_RGB

- (BOOL) isValid
{
    return (_texture != 0);
}

- (NSString *) fragmentShader
{
    return rgbFragmentShaderString;
}

- (void) resolveUniforms: (GLuint) program
{
    _uniformSampler = glGetUniformLocation(program, "s_texture");
}

- (void) setFrame: (KxVideoFrame *) frame
{
    KxVideoFrameRGB *rgbFrame = (KxVideoFrameRGB *)frame;
    
    assert(rgbFrame.rgb.length == rgbFrame.width * rgbFrame.height * 3);
    
    
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    
    if (0 == _texture)
        glGenTextures(1, &_texture);
    
    glBindTexture(GL_TEXTURE_2D, _texture);
    
    glTexImage2D(GL_TEXTURE_2D,
                 0,
                 GL_RGB,
                 frame.width,
                 frame.height,
                 0,
                 GL_RGB,
                 GL_UNSIGNED_BYTE,
                 rgbFrame.rgb.bytes);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
}

- (BOOL) prepareRender
{
    if (_texture == 0)
        return NO;
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _texture);
    glUniform1i(_uniformSampler, 0);
    
    return YES;
}

- (void) dealloc
{
    if (_texture) {
        glDeleteTextures(1, &_texture);
        _texture = 0;
    }
}

@end

@interface KxMovieGLRenderer_YUV : NSObject<KxMovieGLRenderer> {
    
    GLint _uniformSamplers[3];
    GLuint _textures[3];
}
@end

@implementation KxMovieGLRenderer_YUV

- (BOOL) isValid
{
    return (_textures[0] != 0);
}

- (NSString *) fragmentShader
{
    return yuvFragmentShaderString;
}

- (void) resolveUniforms: (GLuint) program
{
    _uniformSamplers[0] = glGetUniformLocation(program, "s_texture_y");
    _uniformSamplers[1] = glGetUniformLocation(program, "s_texture_u");
    _uniformSamplers[2] = glGetUniformLocation(program, "s_texture_v");
}

- (void) setFrame: (KxVideoFrame *) frame
{
    if (!frame)
    {
        NSLog(@"--- GDPlayerView -- setFrame: -- frame = nil!");
        return;
    }
    KxVideoFrameYUV *yuvFrame = (KxVideoFrameYUV *)frame;
    
    if (!yuvFrame.luma || !yuvFrame.chromaB || !yuvFrame.chromaR ) {
        return;
    }
    
    NSUInteger lumaLen = yuvFrame.width * yuvFrame.height;
    NSUInteger chromaBLen = (yuvFrame.width * yuvFrame.height) / 4;
    NSUInteger chromaRLen = (yuvFrame.width * yuvFrame.height) / 4;
    if (lumaLen != yuvFrame.luma.length)
    {
        NSLog(@"--- GDPlayerView -- setFrame: lumaLen 不相等");
        return;
    }
    else
    {
//        NSLog(@"--- GDPlayerView -- setFrame: lumaLen 相等");
    }
    
    if (chromaBLen != yuvFrame.chromaB.length)
    {
        NSLog(@"--- GDPlayerView -- setFrame: chromaBLen 不相等");
        return;
    }
    else
    {
//        NSLog(@"--- GDPlayerView -- setFrame: chromaBLen 相等");
    }
    
    if (chromaRLen != yuvFrame.chromaR.length)
    {
        NSLog(@"--- GDPlayerView -- setFrame: chromaRLen 不相等");
        return;
    }
    else
    {
//        NSLog(@"--- GDPlayerView -- setFrame: chromaRLen 相等");
    }
//    assert(yuvFrame.luma.length == yuvFrame.width * yuvFrame.height);
//    assert(yuvFrame.chromaB.length == (yuvFrame.width * yuvFrame.height) / 4);
//    assert(yuvFrame.chromaR.length == (yuvFrame.width * yuvFrame.height) / 4);
    
    const NSUInteger frameWidth = frame.width;
    const NSUInteger frameHeight = frame.height;
    
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    
    if (0 == _textures[0])
        glGenTextures(3, _textures);
    
    const UInt8 *pixels[3] = { yuvFrame.luma.bytes, yuvFrame.chromaB.bytes, yuvFrame.chromaR.bytes };
    const NSUInteger widths[3]  = { frameWidth, frameWidth / 2, frameWidth / 2 };
    const NSUInteger heights[3] = { frameHeight, frameHeight / 2, frameHeight / 2 };
    
    for (int i = 0; i < 3; ++i) {
        
        glBindTexture(GL_TEXTURE_2D, _textures[i]);
        
        glTexImage2D(GL_TEXTURE_2D,
                     0,
                     GL_LUMINANCE,
                     widths[i],
                     heights[i],
                     0,
                     GL_LUMINANCE,
                     GL_UNSIGNED_BYTE,
                     pixels[i]);
        
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    }
}

- (BOOL) prepareRender
{
    if (_textures[0] == 0)
        return NO;
    
    for (int i = 0; i < 3; ++i) {
        glActiveTexture(GL_TEXTURE0 + i);
        glBindTexture(GL_TEXTURE_2D, _textures[i]);
        glUniform1i(_uniformSamplers[i], i);
    }
    
    return YES;
}

- (void) dealloc
{
    if (_textures[0])
        glDeleteTextures(3, _textures);
}

@end

//////////////////////////////////////////////////////////

#pragma mark - gl view

enum {
    ATTRIBUTE_VERTEX,
   	ATTRIBUTE_TEXCOORD,
};

#pragma mark - GDPlayerView
@implementation GDPlayerView
{
    GLfloat scale;
    NSInteger totalTap;
    BOOL _state;
    
    BOOL _isRenderStatePaused;

    EAGLContext     *_context;
    GLuint          _framebuffer;
    GLuint          _renderbuffer;
    GLint           _backingWidth;
    GLint           _backingHeight;
    GLuint          _program;
    GLint           _uniformMatrix;
    GLfloat         _vertices[8];
    
    id<KxMovieGLRenderer> _renderer;
}



- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        totalTap = 0;
        scale=1;
        _isDragging = NO;
        self.backgroundColor = [UIColor clearColor];
        _renderer = [[KxMovieGLRenderer_YUV alloc] init];
        
//        _renderer = [[KxMovieGLRenderer_RGB alloc] init];
        
        
        CAEAGLLayer *eaglLayer = (CAEAGLLayer*) self.layer;
        eaglLayer.opaque = NO;
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking,
                                        kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat,
                                        nil];
        if(isRetina)
        {
            eaglLayer.contentsScale = 2.0;
        }
        
        _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        
        if (!_context ||
            ![EAGLContext setCurrentContext:_context]) {
            
            NSLog(@"failed to setup EAGLContext");
            self = nil;
            return nil;
        }
        
        glGenFramebuffers(1, &_framebuffer);
        glGenRenderbuffers(1, &_renderbuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
        [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderbuffer);
        
        GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        if (status != GL_FRAMEBUFFER_COMPLETE) {
            
            NSLog(@"failed to make complete framebuffer object %x", status);
            self = nil;
            return nil;
        }
        
        GLenum glError = glGetError();
        if (GL_NO_ERROR != glError) {
            
            NSLog(@"failed to setup GL %x", glError);
            self = nil;
            return nil;
        }
        
        if (![self loadShaders]) {
            
            self = nil;
            return nil;
        }
        
        _vertices[0] = -1.0f;  // x0
        _vertices[1] = -1.0f;  // y0
        _vertices[2] =  1.0f;  // ..
        _vertices[3] = -1.0f;
        _vertices[4] = -1.0f;
        _vertices[5] =  1.0f;
        _vertices[6] =  1.0f;  // x3
        _vertices[7] =  1.0f;  // y3
        
        NSLog(@"OK setup GL");
    }
    
    return self;
}

- (void)dealloc
{
    _renderer = nil;
    _isDragging = YES;
    if (_framebuffer) {
        glDeleteFramebuffers(1, &_framebuffer);
        _framebuffer = 0;
    }

    if (_renderbuffer) {
        glDeleteRenderbuffers(1, &_renderbuffer);
        _renderbuffer = 0;
    }

    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }

    if ([EAGLContext currentContext] == _context) {
        [EAGLContext setCurrentContext:nil];
    }

    _context = nil;
}

- (void)layoutSubviews
{
    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        
        NSLog(@"failed to make complete framebuffer object %x", status);
        
    } else {
        
        NSLog(@"OK setup GL framebuffer %d:%d", _backingWidth, _backingHeight);
    }
    
    [self updateVertices];
    [self render: nil];
}

- (void)setContentMode:(UIViewContentMode)contentMode
{
    [super setContentMode:contentMode];
    [self updateVertices];
    if (_renderer.isValid)
        [self render:nil];
}

- (BOOL)loadShaders
{
    BOOL result = NO;
    GLuint vertShader = 0, fragShader = 0;
    
    _program = glCreateProgram();
    
    vertShader = compileShader(GL_VERTEX_SHADER, vertexShaderString);
    if (!vertShader)
        goto exit;
    
    fragShader = compileShader(GL_FRAGMENT_SHADER, _renderer.fragmentShader);
    if (!fragShader)
        goto exit;
    
    glAttachShader(_program, vertShader);
    glAttachShader(_program, fragShader);
    glBindAttribLocation(_program, ATTRIBUTE_VERTEX, "position");
    glBindAttribLocation(_program, ATTRIBUTE_TEXCOORD, "texcoord");
    
    glLinkProgram(_program);
    
    GLint status;
    glGetProgramiv(_program, GL_LINK_STATUS, &status);
    if (status == GL_FALSE) {
        NSLog(@"Failed to link program %d", _program);
        goto exit;
    }
    
    result = validateProgram(_program);
    
    _uniformMatrix = glGetUniformLocation(_program, "modelViewProjectionMatrix");
    [_renderer resolveUniforms:_program];
    
exit:
    
    if (vertShader)
        glDeleteShader(vertShader);
    if (fragShader)
        glDeleteShader(fragShader);
    
    if (result) {
        
        NSLog(@"OK setup GL programm");
        
    } else {
        
        glDeleteProgram(_program);
        _program = 0;
    }
    
    return result;
}

//AVCodecContext->width
- (void)updateVertices
{
    if (decFrameWidth<=0) {
        decFrameWidth = 1280;
        decFrameHeight = 720;
    }
//    const BOOL fit      = (self.contentMode == UIViewContentModeScaleAspectFit);
    const float width   = _backingWidth;   //_decoder.frameWidth;  640
    const float height  = _backingHeight;  //_decoder.frameHeight; 514
    const float dH      = (float)_backingHeight / height;
    const float dW      = (float)_backingWidth	  / width;
    const float dd      =  MAX(dH, dW); //fit ? MIN(dH, dW) :
    float h       = (height * dd / (float)_backingHeight);
    float w       = (width  * dd / (float)_backingWidth );
    
    NSLog(@"_________updateVertices________%f________%f________",w,h);
    
    w*=scale;
    h*=scale;
    
    _vertices[0] = - w;
    _vertices[1] = - h;
    _vertices[2] =   w;
    _vertices[3] = - h;
    _vertices[4] = - w;
    _vertices[5] =   h;
    _vertices[6] =   w;
    _vertices[7] =   h;
}

- (void)setRenderStatePause:(BOOL)pause{
    _isRenderStatePaused = pause;
}

- (void)render: (KxVideoFrame *) frame
{
    static const GLfloat texCoords[] = {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,
    };
    
    GL_OES_texture_mirrored_repeat;
    GL_APPLE_texture_2D_limited_npot;
    
    [EAGLContext setCurrentContext:_context];
    
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    
    [self configViewSize];
//    glViewport(0, 0, _backingWidth, _backingHeight);
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    if (_isRenderStatePaused) {
        glUseProgram(0);
    }else{
        glUseProgram(_program);
    }
    
    if (frame) {
        [_renderer setFrame:frame];
    }
    
    if ([_renderer prepareRender]) {
        
        GLfloat modelviewProj[16];
        mat4f_LoadOrtho(-1.0f, 1.0f, -1.0f, 1.0f, -1.0f, 1.0f, modelviewProj);
        glUniformMatrix4fv(_uniformMatrix, 1, GL_FALSE, modelviewProj);
        
        glVertexAttribPointer(ATTRIBUTE_VERTEX, 2, GL_FLOAT, 0, 0, _vertices);
        glEnableVertexAttribArray(ATTRIBUTE_VERTEX);
        glVertexAttribPointer(ATTRIBUTE_TEXCOORD, 2, GL_FLOAT, 0, 0, texCoords);
        glEnableVertexAttribArray(ATTRIBUTE_TEXCOORD);
        
#if 0
        if (!validateProgram(_program))
        {
            NSLog(@"Failed to validate program");
            return;
        }
#endif
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    }
    
    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

// You must implement this
+ (Class)layerClass
{
    return [CAEAGLLayer class];
}








-(BOOL)playViewSetup
{
    self.backgroundColor = [UIColor clearColor];
    self.opaque = YES;
    _isRenderStatePaused = NO;
    _state = NO;
    viewmode = 1;
    rotation = 0;
    
    [self configViewSize];
    if (_isdoubleScale) {
        [self addRestures];
    }
	return YES;
}



-(void)addRestures
{
    if (doubleTapRecognizer==nil) {
        self.multipleTouchEnabled = YES;
        
        pinchRecognizer = [[UIPinchGestureRecognizer alloc]initWithTarget:self action:@selector(pinchAction:)];
        pinchRecognizer.delegate = self;
//        doubleTapRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doubleTap)];
//        doubleTapRecognizer.numberOfTapsRequired = 2;
//        doubleTapRecognizer.delegate = self;
        [self addGestureRecognizer:pinchRecognizer];
    }
}


- (void)pinchAction:(UIPinchGestureRecognizer *)sender{
    
    if (scale >1) {
        //缩放
        scale = scale *(1.0f+(sender.scale - 1.0f) * 0.5);
    }
    else{
        scale = scale *(1.0f-(1.0f - sender.scale) * 0.5);
    }
    
    //最大4，最小是1
    if (scale >= 4) {
        scale = 4;
    }
    
    if (scale <=1) {
        scale = 1;
    }
    
    self.contentMode = UIViewContentModeScaleAspectFill;
    dispatch_async(dispatch_get_main_queue(), ^{
        glScalef(scale,scale,1.0f );
    });
    
    
    NSLog(@"ADTest123456--------------%f",sender.scale);
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
	return YES;
}

-(void)scale:(UIPinchGestureRecognizer*)sender
{
    return;
    NSLog(@"-(void)scale1:(UIPinchGestureRecognizer*)sender");

    if([sender state] == UIGestureRecognizerStateBegan)
    {
        lastScale = 1.0;
    }
    else if([sender state] == UIGestureRecognizerStateChanged)
    {
        if (sender.scale > 1)
        {
            scale = (GLfloat)100/99;
        }
        if (sender.scale < 1)
        {
             scale =(GLfloat)99/100;
        }
            //glscalef（）单独调用
        glScalef(scale,scale,1.0f );
        
    }

}

- (int)get_aligned:(int)size
{
    int result = 1;
    while(result < size){
        result *= 2;
    }
    return result;
}

- (void)update_tex_size
{
    texWidth = [self get_aligned:decFrameWidth];
    texHeight = [self get_aligned:decFrameHeight];
    // NSLog(@"update_tex_size texWidth = %d,texHeight = %d",texWidth,texHeight);
}

- (void)configViewSize {
    
    [self update_tex_size];

    if(isRetina)
    {
        _backingWidth = [self bounds].size.width*2;
        _backingHeight = [self bounds].size.height*2;
    }
    else
    {
        _backingWidth = [self bounds].size.width;
        _backingHeight = [self bounds].size.height;
    }
//    NSLog(@"__________configView_Size________%d_____%d\n", _backingWidth, _backingHeight);
    
    glViewport(0, 0, _backingWidth, _backingHeight);
}

-(void)drag:(UIPanGestureRecognizer*)sender
{
}

- (void)setupView:(int)width setHeight:(int)height;
{
    if (width>0) {
        decFrameWidth = width;
    }
    
    if (height>0) {
        decFrameHeight = height;
    }
}

- (void)setupViewMode:(int)mode
{
    viewmode = mode;
}


// Updates the OpenGL view when the timer fires
- (void)drawVideo:(void*)data
{
}


// Release resources when they are no longer needed.


-(void)hideToolBar
{
    [toolBar setHidden:YES];
}

-(void)singleTap
{
	return;
    if (toolBar.hidden) {
        [toolBar setHidden:NO];
        [self performSelector:@selector(hideToolBar) withObject:nil afterDelay:3];
    }
    else {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideToolBar) object:nil];
        [self hideToolBar];
    }
}

-(void)doubleTap
{
    scale *= 1.5f;
    
    totalTap++;
    
    if (totalTap>=4)
    {
        totalTap = 0;
        
        scale = 1;//(GLfloat)8/27;
        
//        self.contentMode = UIViewContentModeScaleAspectFit;
    }else{
        
    }
    self.contentMode = UIViewContentModeScaleAspectFill;


    dispatch_async(dispatch_get_main_queue(), ^{
        glScalef(scale,scale,1.0f );
    });
//    glFlush ();
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    return;
    	//    if([touches count] == 2) return;
    UITouch * touch = [touches anyObject];
    switch(touch.tapCount){
        case 1:
            [self performSelector:@selector(singleTap) withObject:nil afterDelay:.3];
            break;
        case 2:
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(singleTap) object:nil];
            [self doubleTap];
            break;
        default:
            break;
    }
}

@end
