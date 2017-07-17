//
//  ffmpeg.h
//  TSClipEditor
//
//  Created by Antelis on 26/06/2017.
//  Copyright © 2017 shion. All rights reserved.
//

#ifndef ffmpeg_h
#define ffmpeg_h

#include <stdio.h>
#import <CoreGraphics/CoreGraphics.h>

void print_err(int ret);
const char * strFromErr(int ret);
int is_eof(int ret);
int err2averr(int ret);
void cleanContext(void);
int getVideoDurationWithLoc(const char* fileLoc);
CGImageRef getVideoThumbAtPosition(double second);

#endif /* ffmpeg_h */
