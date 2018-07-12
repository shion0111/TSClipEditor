//
//  VideoState.h
//  libVidPlayer
//
//  Created by Antelis on 2017/8/11.
//  Copyright © 2017 Antelis. All rights reserved.
//

@import AudioToolbox;

#include <pthread.h>

#import <libavformat/avformat.h>
#import <libavcodec/avcodec.h>
#import <libavutil/avutil.h>
#import <libavutil/time.h>
#import <libswresample/swresample.h>



@class VidPlayerDecoder;
@protocol VidPlayerVideoOutput;

// This is an object rather than a struct because ObjC ARC requires that for having dispatch_queue_t members.
@interface VideoState : NSObject {
@public
    bool paused;
    // Pausing/unpausing is async.  It works by setting this to the desired value, and then the decoders_thread noticing the discrepancy and making the actual change.
    bool requested_paused;

    int playback_speed_percent;
    int volume_percent;
    __weak id<VidPlayerVideoOutput> weak_output;

    bool abort_request;
    bool seek_req;
    // xxx eliminate seek_from!
    int64_t seek_from;
    int64_t seek_to;
    bool paused_for_eof;

    AVFormatContext *ic;
    VidPlayerDecoder* auddec;
    VidPlayerDecoder* viddec;

    // Serial numbers are use to flush out obsolete packets/frames after seeking.  We increment ->current_serial each time we seek.
    int current_serial;
    dispatch_queue_t decoder_queue;
    dispatch_group_t decoder_group;

    pthread_mutex_t decoders_mutex;
    pthread_cond_t decoders_cond;

    // Clock (i.e. the current time in a movie, in usec, based on audio playback time).

    int64_t clock_pts; // The pts of a recently-played audio frame.
    int64_t clock_last_updated; // The machine/wallclock time the clock was last set.

    // Audio

    bool audio_needs_interleaving;
    enum AVSampleFormat audio_tgt_fmt;
    int64_t current_audio_frame_pts;
    size_t current_audio_frame_buffer_offset;
    AudioChannelLayout *audio_channel_layout; // used if there's >2 channels
    AudioQueueRef audio_queue;
    dispatch_queue_t audio_dispatch_queue;
    dispatch_group_t audio_dispatch_group;

    // Video

    int width, height;
    int last_shown_frame_serial;
}
@end;


// core

VideoState* movie_open(NSURL *sourceURL);
void movie_close(VideoState *mov);

void vp_seek(VideoState *mov, int64_t pos, int64_t current_pos);

void vp_set_paused(VideoState *mov, bool pause);

int vp_get_playback_speed_percent(VideoState *mov);
void vp_set_playback_speed_percent(VideoState *mov, int speed);

void decoders_thread(VideoState *mov);
void decoders_wake_thread(VideoState *mov);


// video

void vp_if_new_video_frame_is_available_then_run(VideoState *mov, void (^func)(AVFrame *));


// audio

int audio_open(VideoState *mov, AVCodecContext *avctx);
void audio_queue_destroy(VideoState *mov);

void audio_queue_set_paused(VideoState *mov, bool pause);
void vp_audio_update_speed(VideoState *mov);
void vp_set_volume_percent(VideoState *mov, int volume);


// clock

int64_t clock_get_usec(VideoState *mov);
void clock_set(VideoState *mov, int64_t pts);
void clock_preserve(VideoState *mov);
