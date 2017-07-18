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

typedef void (*CutClipProgressCallback)(void *observer, float current, float total);
typedef void (*CutClipFinishCallback)(void *observer);

void print_err(int ret);
const char * strFromErr(int ret);
int is_eof(int ret);
int err2averr(int ret);
void cleanVideoContext(void);
int getVideoDurationWithLoc(const char* fileLoc);
CGImageRef getVideoThumbAtPosition(double second);
int SaveClipWithInfo(float from_seconds,
                     float end_seconds,
                     const char* out_filename,
                     const void *observer,
                     const CutClipProgressCallback progresscallback,
                     const CutClipFinishCallback finishcallback);
#endif /* ffmpeg_h */
