//
//  VidPlayerVideo+Internal.h
//  libVidPlayer
//
//  Created by Antelis on 2017/8/13.
//  Copyright © 2017 Antelis. All rights reserved.
//

#import "VidPlayerVideo.h"
#import "VideoState.h"

typedef struct IntSize_ { int width, height; } IntSize;

@interface VidPlayerVideo (Internal)
-(IntSize) sizeForGLTextures;
-(void) ifNewVideoFrameIsAvailableThenRun:(void (^)(AVFrame *))func;
@end
