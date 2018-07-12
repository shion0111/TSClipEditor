//
//  VidPlayerLayer.h
//  libVidPlayer
//
//  Created by Antelis on 2017/8/12.
//  Copyright © 2017 Antelis. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VidPlayerVideo.h"

@interface VidPlayerLayer : CAOpenGLLayer <VidPlayerVideoOutput>
{
    VidPlayerVideo *_movie;

@private
    NSLock *_lock;

    CGLContextObj _cglContext;

    GLuint _program;
    GLuint _location_y;
    GLuint _location_u;
    GLuint _location_v;
    GLuint _vertex_buffer;
    GLuint _texture_vertex_buffer;
    GLuint _textures[3]; // in Y U V order
}

@property (retain) VidPlayerVideo *movie;

-(void) invalidate;

@end
