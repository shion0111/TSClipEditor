//
//  VidPlayerLayer.m
//  libVidPlayer
//
//  Created by Antelis on 2017/8/12.
//  Copyright © 2017 Antelis. All rights reserved.
//

#import "VidPlayerLayer.h"
#import "VidPlayerVideo+Internal.h"

#import <OpenGL/gl3.h>


@implementation VidPlayerLayer

void displayReconfigurationCallBack(CGDirectDisplayID display,
                                      CGDisplayChangeSummaryFlags flags,
                                      void *userInfo)
{
    @autoreleasepool {
        if (flags & kCGDisplaySetModeFlag) {
            VidPlayerLayer *self = (__bridge VidPlayerLayer *)userInfo;
            dispatch_async(dispatch_get_main_queue(), ^{
                // TODO: Not enough for GPU switching...
                self.asynchronous = NO;
                self.asynchronous = YES;
            } );
        }
    }
}

-(void) invalidateWithNotification:(NSNotification*)inNotification {
    [self invalidate];
}

-(void) invalidate {
    self.asynchronous = NO;
    CGDisplayRemoveReconfigurationCallback(displayReconfigurationCallBack, (__bridge void *)(self));

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (_movie) {
        [_movie invalidate];
        _movie = NULL;
    }
    if (_lock) _lock = NULL;
}

-(void) dealloc {
    [self invalidate];
}

-(instancetype) init {
    self = [super init];
    if (self) {
        self.needsDisplayOnBoundsChange = YES;

        _lock = [[NSLock alloc] init];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(invalidateWithNotification:) name:NSApplicationWillTerminateNotification object:nil];

        CGDisplayRegisterReconfigurationCallback(displayReconfigurationCallBack, (__bridge void *)(self));
    }
    return self;
}

-(CGLPixelFormatObj) copyCGLPixelFormatForDisplayMask:(uint32_t)mask {
    GLint numPixelFormats = 0;
    CGLPixelFormatAttribute attributes[] = {
        kCGLPFAOpenGLProfile, (CGLPixelFormatAttribute) kCGLOGLPVersion_GL3_Core,
        kCGLPFADisplayMask, mask,
        kCGLPFADoubleBuffer,
        kCGLPFAColorSize, 24,
        kCGLPFAAlphaSize, 8,
        // //kCGLPFADepthSize, 16,    // no depth buffer
        kCGLPFAMultisample,
        kCGLPFASampleBuffers, 1,
        // Disabled because it leads to glError() returning non-zero at the start of -drawInCGLContext.
        // kCGLPFASamples, 4,
        0
    };
    CGLPixelFormatObj pixelFormat;
    CGLError err = CGLChoosePixelFormat(attributes, &pixelFormat, &numPixelFormats);
    if (err || !pixelFormat) {
        NSLog(@"CGLChoosePixelFormat failed %d: %s", err, CGLErrorString(err));
    }
    return pixelFormat;
}

-(BOOL) canDrawInCGLContext:(CGLContextObj)glContext
                 pixelFormat:(CGLPixelFormatObj)pixelFormat
                forLayerTime:(CFTimeInterval)timeInterval
                 displayTime:(const CVTimeStamp *)timeStamp
{
    return _movie && !NSEqualSizes(_movie.naturalSize, NSZeroSize);
}

-(void) drawInCGLContext:(CGLContextObj)glContext
              pixelFormat:(CGLPixelFormatObj)pixelFormat
             forLayerTime:(CFTimeInterval)timeInterval
              displayTime:(const CVTimeStamp *)timeStamp
{
    CGLSetCurrentContext(glContext);
    if (glContext != _cglContext) {
        _cglContext = glContext;
        [self _gl_init];
    }
    [self _gl_draw];
    [super drawInCGLContext:glContext
                pixelFormat:pixelFormat
               forLayerTime:timeInterval
                displayTime:timeStamp];
}


/* =============================================================================================== */

#pragma mark -
#pragma mark public

-(VidPlayerVideo*) movie {
    return _movie;
}

-(void) setMovie:(VidPlayerVideo*)movie {
    self.asynchronous = NO;
    [_lock lock];

    if(_movie) [_movie invalidate];
    _movie = movie;
    if(_movie) {
        [_movie setOutput:self];
        [self setNeedsDisplay];
    }

    [_lock unlock];
    self.asynchronous = movie ? !movie.paused : false;
}


/* =============================================================================================== */

#pragma mark -
#pragma mark VidPlayerVideoOutput impl

// Called e.g. after seeking while paused.
-(void) movieOutputNeedsSingleUpdate {
    // -setNeedsDisplay does nothing if called off the main thread.
    if(!NSThread.isMainThread) return dispatch_async(dispatch_get_main_queue(), ^{
        [self movieOutputNeedsSingleUpdate];
    });
    [self setNeedsDisplay];
}

// Called when playback starts or stops.
// Note: the internals rely on this triggering periodic calls to vp_get_current_frame() and thus draining the video frameq.
-(void) movieOutputNeedsContinuousUpdating:(bool)continuousUpdating {
    // Setting .asynchronous from off the main thread mutates the stored value, but doesn't actually have the needed side effect of starting/stopping the ~60fps timer that calls -canDrawInCGLContext:/-drawInCGLContext:
    if(!NSThread.isMainThread) return dispatch_async(dispatch_get_main_queue(), ^{
        [self movieOutputNeedsContinuousUpdating:continuousUpdating];
    });
    self.asynchronous = continuousUpdating;
}


/* =============================================================================================== */

#pragma mark -
#pragma mark OpenGL-based drawing code

static const char *const vertex_shader_src = "                               \
    #version 330 core                                                        \
    layout(location = 0) in vec3 vertexPosition_modelspace;                  \
    layout(location = 1) in vec2 vertexUV;                                   \
    out vec2 texcoord;                                                       \
    void main() {                                                            \
        gl_Position.xyz = vertexPosition_modelspace;                         \
        texcoord = vertexUV;                                                 \
    }                                                                        \
";

static const char *const fragment_shader_src = "                             \
    #version 330 core                                                        \
    in vec2 texcoord;                                                        \
    out vec3 color;                                                          \
    uniform sampler2D video_data_y;                                          \
    uniform sampler2D video_data_u;                                          \
    uniform sampler2D video_data_v;                                          \
    void main() {                                                            \
        float y = texture(video_data_y, texcoord).r;                         \
        float u = texture(video_data_u, texcoord).r - 0.5;                   \
        float v = texture(video_data_v, texcoord).r - 0.5;                   \
        float r = y + 1.402 * v;                                             \
        float g = y - 0.344 * u - 0.714 * v;                                 \
        float b = y + 1.772 * u;                                             \
        color = vec3(r, g, b);                                               \
    }                                                                        \
";

-(void) _gl_init {
    _program = load_shaders(vertex_shader_src, fragment_shader_src) ;
    _location_y = glGetUniformLocation(_program, "video_data_y");
    _location_u = glGetUniformLocation(_program, "video_data_u");
    _location_v = glGetUniformLocation(_program, "video_data_v");

    const GLfloat vertex_data[] = {
        -1.0f, -1.0f, 0.0f,
        1.0f, -1.0f, 0.0f,
        -1.0f, 1.0f, 0.0f,
        1.0f, 1.0f, 0.0f,
    };
    glGenBuffers(1, &_vertex_buffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertex_buffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertex_data), vertex_data, GL_STATIC_DRAW);

    const GLfloat texture_vertex_data[] = {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,
    };
    glGenBuffers(1, &_texture_vertex_buffer);
    glBindBuffer(GL_ARRAY_BUFFER, _texture_vertex_buffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(texture_vertex_data), texture_vertex_data, GL_STATIC_DRAW);

    glGenTextures(3, _textures);
    for(int i = 0; i < 3; ++i) {
        glBindTexture(GL_TEXTURE_2D, _textures[i]);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    }
}

GLuint load_shaders(const char * VertexShaderCode, const char * FragmentShaderCode) {
    GLuint vertex_shader_id = init_shader(GL_VERTEX_SHADER, VertexShaderCode);
    GLuint fragment_shader_id = init_shader(GL_FRAGMENT_SHADER, FragmentShaderCode);

    GLuint prog_id = glCreateProgram();
    glAttachShader(prog_id, vertex_shader_id);
    glAttachShader(prog_id, fragment_shader_id);
    glLinkProgram(prog_id);

    GLint Result = GL_FALSE;
    glGetProgramiv(prog_id, GL_LINK_STATUS, &Result);
    int info_log_length;
    glGetProgramiv(prog_id, GL_INFO_LOG_LENGTH, &info_log_length);
    if(info_log_length > 0) {
        char* err = malloc(info_log_length + 1);
        glGetProgramInfoLog(prog_id, info_log_length, NULL, err);
        NSLog(@"libVidPlayer: error linking shader:\n%s", err);
        free(err);
        return 0;
    }

    glDetachShader(prog_id, vertex_shader_id);
    glDetachShader(prog_id, fragment_shader_id);
    glDeleteShader(vertex_shader_id);
    glDeleteShader(fragment_shader_id);
    return prog_id;
}

GLuint init_shader(GLenum kind, const char* code) {
    GLuint shader_id = glCreateShader(kind);
    glShaderSource(shader_id, 1, &code , NULL);
    glCompileShader(shader_id);
    GLint Result = GL_FALSE;
    glGetShaderiv(shader_id, GL_COMPILE_STATUS, &Result);
    int info_log_length;
    glGetShaderiv(shader_id, GL_INFO_LOG_LENGTH, &info_log_length);
    if(info_log_length > 0) {
        char* err = malloc(info_log_length + 1);
        glGetShaderInfoLog(shader_id, info_log_length, NULL, err);
        NSLog(@"libVidPlayer: error compiling shader:\n%s", err);
        free(err);
        return 0;
    }
    return shader_id;
}

-(void) _gl_draw {
    [_lock lock];

    // We always need to re-render, but if the frame is unchanged we don't upload new texture data).
    [_movie ifNewVideoFrameIsAvailableThenRun:^(AVFrame *fr) {
        // Pixel formats other than AV_PIX_FMT_YUV420P are vanishingly rare, so don't bother with them, at least for now.
        // If we ever do handle them, ideally it'd be here in VidPlayerLayer, by using different shaders.
        if (fr->format != AV_PIX_FMT_YUV420P) return;

        IntSize sz = [self->_movie sizeForGLTextures];
        glBindTexture(GL_TEXTURE_2D, self->_textures[0]);
        glPixelStorei(GL_UNPACK_ROW_LENGTH, fr->linesize[0]);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RED, sz.width, sz.height, 0, GL_RED, GL_UNSIGNED_BYTE, fr->data[0]);
        glBindTexture(GL_TEXTURE_2D, self->_textures[1]);
        glPixelStorei(GL_UNPACK_ROW_LENGTH, fr->linesize[1]);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RED, sz.width / 2, sz.height / 2, 0, GL_RED, GL_UNSIGNED_BYTE, fr->data[1]);
        glBindTexture(GL_TEXTURE_2D, self->_textures[2]);
        glPixelStorei(GL_UNPACK_ROW_LENGTH, fr->linesize[2]);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RED, sz.width / 2, sz.height / 2, 0, GL_RED, GL_UNSIGNED_BYTE, fr->data[2]);
    }];

    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    GLuint vertex_array_id;
    glGenVertexArrays(1, &vertex_array_id);
    glBindVertexArray(vertex_array_id);

    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    glUseProgram(_program);

    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _textures[0]);
    glUniform1i(_location_y, 0);

    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, _textures[1]);
    glUniform1i(_location_u, 1);

    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, _textures[2]);
    glUniform1i(_location_v, 2);

    glEnableVertexAttribArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, _vertex_buffer);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, NULL);

    glEnableVertexAttribArray(1);
    glBindBuffer(GL_ARRAY_BUFFER, _texture_vertex_buffer);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 0, NULL);

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

    glDisableVertexAttribArray(0);
    glDisableVertexAttribArray(1);

    glDeleteVertexArrays(1, &vertex_array_id);

    [_lock unlock];
}

@end
