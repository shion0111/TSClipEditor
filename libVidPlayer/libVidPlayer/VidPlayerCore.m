//
//  VidPlayerCore.m
//  libVidPlayer
//
//  Created by Antelis on 2017/8/11.
//  Copyright © 2017 Antelis. All rights reserved.
//


#import "VideoState.h"
#import "VidPlayerVideo+Internal.h"
#import "VidPlayerDecoder.h"


static int movie_stream_open(VideoState *mov, VidPlayerDecoder *dec, AVStream *stream);
static int movie_open_helper(VideoState *mov, NSURL *source_url);
static int decode_interrupt_cb(void *ctx);


VideoState* movie_open(NSURL *source_url)
{
    VideoState *mov = [[VideoState alloc] init];
    if (movie_open_helper(mov, source_url) < 0) {
        movie_close(mov);
        return NULL;
    }
    return mov;
}

static int movie_open_helper(VideoState *mov, NSURL *source_url)
{
    mov->volume_percent = 100;
    mov->weak_output = NULL;
    mov->paused = true;
    mov->requested_paused = true;
    mov->playback_speed_percent = 100;
    mov->abort_request = false;
    mov->seek_req = false;
    mov->last_shown_frame_serial = -1;

    int err = pthread_mutex_init(&mov->decoders_mutex, NULL);
    if (err) return -1;
    err = pthread_cond_init(&mov->decoders_cond, NULL);
    if (err) return -1;

    av_log_set_flags(AV_LOG_SKIP_REPEATED);
    av_register_all();

    mov->ic = avformat_alloc_context();
    if (!mov->ic) return -1;
    mov->ic->interrupt_callback.callback = decode_interrupt_cb;
    mov->ic->interrupt_callback.opaque = (__bridge void*) mov;
    err = avformat_open_input(&mov->ic, source_url.path.fileSystemRepresentation, NULL, NULL);
    if (err < 0) return -1;

    err = avformat_find_stream_info(mov->ic, NULL);
    if (err < 0) return -1;

    if (mov->ic->pb) mov->ic->pb->eof_reached = 0; // FIXME hack, ffplay maybe should not use avio_feof() to test for the end

    for (int i = 0; i < mov->ic->nb_streams; ++i) mov->ic->streams[i]->discard = AVDISCARD_ALL;

    int vid_index = av_find_best_stream(mov->ic, AVMEDIA_TYPE_VIDEO, -1, -1, NULL, 0);
    if (vid_index < 0) return -1;
    int aud_index = av_find_best_stream(mov->ic, AVMEDIA_TYPE_AUDIO, -1, vid_index, NULL, 0);
    if (aud_index < 0) return -1;
    mov->auddec = [[VidPlayerDecoder alloc] init];
    if (movie_stream_open(mov, mov->auddec, mov->ic->streams[aud_index]) < 0)
        return -1;
    if (audio_open(mov, mov->auddec->avctx) < 0)
        return -1;
    AVStream *vidstream = mov->ic->streams[vid_index];
    if (vidstream->disposition & AV_DISPOSITION_ATTACHED_PIC)
        return -1;
    mov->width = vidstream->codecpar->width;
    mov->height = vidstream->codecpar->height;
    mov->viddec = [[VidPlayerDecoder alloc] init];
    if (movie_stream_open(mov, mov->viddec, vidstream) < 0)
        return -1;

    mov->decoder_queue = dispatch_queue_create("decoders", NULL);
    mov->decoder_group = dispatch_group_create();
    dispatch_group_async(mov->decoder_group, mov->decoder_queue, ^(void) {
        decoders_thread(mov);
    });

    return 0;
}

static int movie_stream_open(VideoState *mov, VidPlayerDecoder *dec, AVStream *stream)
{
    dec->avctx = avcodec_alloc_context3(NULL);
    AVCodecContext *avctx = dec->avctx;
    if (!avctx)
        return AVERROR(ENOMEM);

    int err = avcodec_parameters_to_context(avctx, stream->codecpar);
    if (err < 0)
        return err;
    av_codec_set_pkt_timebase(avctx, stream->time_base);

    AVCodec *codec = avcodec_find_decoder(avctx->codec_id);
    if (!codec) {
        NSLog(@"libVidPlayer: no codec could be found with id %d\n", avctx->codec_id);
        return AVERROR(EINVAL);
    }

    avctx->codec_id = codec->id;
    avctx->workaround_bugs = 1;
    av_codec_set_lowres(avctx, 0);
    avctx->error_concealment = 3;

    avctx->thread_count = 0; // Tell ffmpeg to choose an appropriate number.
    if (avcodec_open2(avctx, codec, NULL) < 0)
        return -1;

    stream->discard = AVDISCARD_DEFAULT;

    if (decoder_init(dec, avctx, stream) < 0)
        return -1;

    return 0;
}

void movie_close(VideoState *mov)
{
    if (!mov) return;
    mov->abort_request = true;

    decoders_wake_thread(mov);
    dispatch_group_wait(mov->decoder_group, DISPATCH_TIME_FOREVER);
    mov->decoder_group = NULL;
    mov->decoder_queue = NULL;

    audio_queue_destroy(mov);

    if (mov->auddec) decoder_destroy(mov->auddec);
    if (mov->viddec) decoder_destroy(mov->viddec);

    avformat_close_input(&mov->ic);

    pthread_mutex_destroy(&mov->decoders_mutex);
    pthread_cond_destroy(&mov->decoders_cond);

    mov->weak_output = NULL;
}

static int decode_interrupt_cb(void *ctx)
{
    VideoState *mov = (__bridge VideoState *)(ctx);
    return mov->abort_request;
}

int64_t clock_get_usec(VideoState *mov)
{
    if (mov->paused)
        return mov->clock_pts;
    return mov->clock_pts + (av_gettime_relative() - mov->clock_last_updated) * mov->playback_speed_percent / 100;
}

void clock_set(VideoState *mov, int64_t pts)
{
    mov->clock_pts = pts;
    mov->clock_last_updated = av_gettime_relative();
}

void clock_preserve(VideoState *mov)
{
    // This ensures the clock is correct after pausing, unpausing, or changing speed change (all of which would invalidate the basic calculation done by clock_get_usec, for different reasons).
    clock_set(mov, clock_get_usec(mov));
}

static int decoders_get_packet(VideoState *mov, AVPacket *pkt, bool *reached_eof)
{
    if (mov->abort_request) return -1;
    int ret = av_read_frame(mov->ic, pkt);
    if (ret < 0) {
        if ((ret == AVERROR_EOF || avio_feof(mov->ic->pb)) && !*reached_eof) {
            *reached_eof = true;
        }
        if (mov->ic->pb && mov->ic->pb->error)
            return -1; // xxx unsure about this
        return 0;
    }
    *reached_eof = false;
    return 0;
}

void vp_seek(VideoState *mov, int64_t pos, int64_t current_pos)
{
    if (!mov->seek_req) {
        mov->seek_from = current_pos;
        mov->seek_to = pos;
        mov->seek_req = true;
        decoders_wake_thread(mov);
    }
}

void vp_set_paused(VideoState *mov, bool pause)
{
    // Allowing unpause in this case would just let the clock run beyond the duration.
    if (!pause && mov->paused && mov->paused_for_eof)
        return;
    if (pause == mov->requested_paused)
        return;
    mov->requested_paused = pause;
    decoders_wake_thread(mov);
}

void vp_set_playback_speed_percent(VideoState *mov, int speed)
{
    if (speed <= 0) return;
    if (mov->playback_speed_percent == speed) return;
    mov->playback_speed_percent = speed;
    clock_preserve(mov);
    vp_audio_update_speed(mov);
}

void decoders_thread(VideoState *mov)
{
    AVPacket pkt;
    int err = 0;
    bool reached_eof = false;
    bool aud_frames_pending = false;
    bool vid_frames_pending = false;
    // These both start true because we start paused, and want a clock and video update ASAP, which is equivalent to the seek-while-paused case.
    bool need_video_update_after_seeking_while_paused = true;
    bool need_clock_update_after_seeking = true;

    for (;;) {
        if (mov->abort_request) break;

        bool pause = mov->requested_paused;
        if (mov->paused != pause) {
            clock_preserve(mov);
            mov->paused = pause;
            audio_queue_set_paused(mov, pause);
            __strong id<VidPlayerVideoOutput> output = mov->weak_output;
            if (output) [output movieOutputNeedsContinuousUpdating:!pause];
            need_video_update_after_seeking_while_paused = false;
            continue;
        }

        if (mov->seek_req) {
            int64_t seek_diff = mov->seek_to - mov->seek_from;
            // When trying to seek forward a small distance, we need to specifiy a time in the future as the minimum acceptable seek position, since otherwise the seek could end up going backward slightly (e.g. if keyframes are ~10s apart and we were ~2s past one and request a +5s seek, the key frame immediately before the target time is the one we're just past, and is what avformat_seek_file will seek to).  The "/ 2" is a fairly arbitrary choice.
            int64_t seek_min = seek_diff > 0 ? mov->seek_to - (seek_diff / 2) : INT64_MIN;
            int ret = avformat_seek_file(mov->ic, -1, seek_min, mov->seek_to, INT64_MAX, 0);
            mov->seek_req = false;
            if (ret < 0)
                continue;

            mov->paused_for_eof = false;
            ++mov->current_serial;
            reached_eof = false;
            aud_frames_pending = false;
            vid_frames_pending = false;
            decoder_flush(mov->auddec);
            decoder_flush(mov->viddec);
            need_clock_update_after_seeking = true;
            // Clear out stale frames so there's space for new ones.  This is not strictly necessary if we're not paused, as the code that consumes the frames will do the same, but it seems simpler to be consistent.
            decoder_peek_current_frame(mov->auddec, mov);
            decoder_peek_current_frame(mov->viddec, mov);
            need_video_update_after_seeking_while_paused = mov->paused;
            continue;
        }

        if (need_video_update_after_seeking_while_paused && decoder_peek_current_frame(mov->viddec, mov)) {
            __strong id<VidPlayerVideoOutput> output = mov->weak_output;
            if (output) [output movieOutputNeedsSingleUpdate];
            need_video_update_after_seeking_while_paused = false;
            continue;
        }
        if (need_clock_update_after_seeking) {
            Frame *fr;
            if ((fr = decoder_peek_current_frame(mov->auddec, mov))) {
                clock_set(mov, fr->frm_pts_usec);
                need_clock_update_after_seeking = false;
            }
        }

        // Note: there can be frames pending even after reached_eof is set (there just shouldn't be any further packets).
        if (aud_frames_pending && !decoder_frameq_is_full(mov->auddec)) {
            aud_frames_pending = decoder_receive_frame(mov->auddec, mov->current_serial, mov);
            continue;
        }
        if (vid_frames_pending && !decoder_frameq_is_full(mov->viddec)) {
            vid_frames_pending = decoder_receive_frame(mov->viddec, mov->current_serial, mov);
            continue;
        }

        // Pause at EOF (so we don't waste CPU refreshing the CALayer when nothing has changed).
        if (reached_eof && !mov->paused && decoder_finished(mov->auddec, mov->current_serial) && decoder_finished(mov->viddec, mov->current_serial)) {
            mov->paused_for_eof = true;
            mov->requested_paused = true;
            continue;
        }

        if (reached_eof || aud_frames_pending || vid_frames_pending) {
            // For aud_frames_pending or vid_frames_pending, we need to wait until there's space in the frameq (or until we get interrupted to handle close/seek/pause/whatever).  For reached_eof we just need to wait for close/seek/pause/whatever.
            // We'll wake up unnecessarily sometimes (e.g. in the reached_eof case we'll wake >FRAME_QUEUE_SIZE times as each of the remaining frames is drained from the queue), but that's harmless.
            pthread_mutex_lock(&mov->decoders_mutex);
            pthread_cond_wait(&mov->decoders_cond, &mov->decoders_mutex);
            pthread_mutex_unlock(&mov->decoders_mutex);
            continue;
        }

        bool prev_reached_eof = reached_eof;
        err = decoders_get_packet(mov, &pkt, &reached_eof);
        if (err < 0) break;
        if (reached_eof && !prev_reached_eof) {
            aud_frames_pending = decoder_send_packet(mov->auddec, NULL);
            vid_frames_pending = decoder_send_packet(mov->viddec, NULL);
            continue;
        }

        if (pkt.stream_index == mov->auddec->stream->index) {
            aud_frames_pending = decoder_send_packet(mov->auddec, &pkt);
        } else if (pkt.stream_index == mov->viddec->stream->index) {
            vid_frames_pending = decoder_send_packet(mov->viddec, &pkt);
        } else {
            av_packet_unref(&pkt);
        }
    }
}

void decoders_wake_thread(VideoState *mov)
{
    pthread_cond_signal(&mov->decoders_cond);
}
