//
//  VidPlayerVideo.m
//  libVidPlayer
//
//  Created by Antelis on 2017/8/13.
//  Copyright © 2017 Antelis. All rights reserved.
//

#import "VidPlayerVideo.h"
#import "VidPlayerVideo+Internal.h"

#import "VideoState.h"
#import "VidPlayerDecoder.h"


@implementation VidPlayerVideo

-(instancetype) initWithURL:(NSURL *)sourceURL error:(NSError **)errorPtr {
    self = [super init];
    if(self) {
        mov = movie_open(sourceURL);
        if(!mov) return nil;
    }
    return self;
}

-(void) dealloc {
    [self invalidate];
}

-(void) invalidate {
    if(!mov) return;
    self.paused = true;
    movie_close(mov);
    mov = NULL;
}

-(void) setOutput:(id<VidPlayerVideoOutput>)output {
    if(!mov) return;
    mov->weak_output = output;
}

-(NSSize) naturalSize {
    if(!mov) return NSMakeSize(1, 1);
    // Use the stream aspect ratio
    AVRational sRatio = mov->viddec->stream->sample_aspect_ratio;
    if(sRatio.num && sRatio.den) return NSMakeSize(mov->width * sRatio.num / sRatio.den, mov->height);
    // Or use the codec aspect ratio
    AVRational cRatio = mov->viddec->stream->codecpar->sample_aspect_ratio;
    if(cRatio.num && cRatio.den) return NSMakeSize(mov->width * cRatio.num / cRatio.den, mov->height);
    return NSMakeSize(mov->width, mov->height);
}

// I *think* (but am not certain) that the difference from the above is that this ignores the possibility of rectangular pixels.
-(IntSize) sizeForGLTextures {
    if(!mov) return (IntSize) { 1, 1 };
    return (IntSize) { mov->width, mov->height };
}

-(int64_t) durationInMicroseconds {
    if(!mov) return 0;
    return mov->ic->duration;
}

-(int64_t) currentTimeInMicroseconds {
    if(!mov) return 0;
    return clock_get_usec(mov);
}

-(double) currentTimeAsFraction {
    int64_t position = self.currentTimeInMicroseconds;
    int64_t duration = self.durationInMicroseconds;
    if(duration == 0) return 0;
    position = (position < 0 ? 0 : position);
    position = (position > duration ? duration : position);
    return (double)position/duration;
}

-(void) setCurrentTimeAsFraction:(double)pos {
    self.currentTimeInMicroseconds = (int64_t) (pos * self.durationInMicroseconds);
}

-(void) setCurrentTimeInMicroseconds:(int64_t)newTime {
    if(!mov) return;
    if(newTime < 0) newTime = 0;
    if(newTime > self.durationInMicroseconds) newTime = self.durationInMicroseconds;
    if(mov->ic->start_time != AV_NOPTS_VALUE) newTime += mov->ic->start_time;
    vp_seek(mov, newTime, self.currentTimeInMicroseconds);
}

-(bool) paused {
    if(!mov) return true;
    // Pausing/unpausing is async, but the caller is unlikely to want to know about that.
    return mov->requested_paused;
}

-(void) setPaused:(bool)shouldPause {
    if(!mov) return;
    vp_set_paused(mov, shouldPause);
}

-(int) playbackSpeedPercent {
    if(!mov) return 100;
    return mov->playback_speed_percent;
}

-(void) setPlaybackSpeedPercent:(int)speed {
    if(!mov) return;
    vp_set_playback_speed_percent(mov, speed);
}

-(int) volumePercent {
    if(!mov) return 100;
    return mov->volume_percent;
}

-(void) setVolumePercent:(int)volume {
    if(!mov) return;
    vp_set_volume_percent(mov, volume);
}

-(void) ifNewVideoFrameIsAvailableThenRun:(void (^)(AVFrame *))func {
    if(!mov) return;
    vp_if_new_video_frame_is_available_then_run(mov, func);
}

@end
