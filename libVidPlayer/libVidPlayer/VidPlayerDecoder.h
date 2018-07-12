//
//  VidPlayerDecoder.h
//  libVidPlayer
//
//  Created by Antelis on 2017/8/11.
//  Copyright © 2017 Antelis. All rights reserved.
//

#import "VideoState.h"


#define FRAME_QUEUE_SIZE 100

typedef struct Frame {
    AVFrame *frm_frame;
    int frm_serial;
    int64_t frm_pts_usec;
} Frame;

@interface VidPlayerDecoder : NSObject {
@public
    AVStream *stream;
    AVCodecContext *avctx;
    int finished;
    int64_t next_pts;
    AVRational next_pts_tb;
    AVFrame *tmp_frame;

    Frame frameq[FRAME_QUEUE_SIZE];
    // If frameq_head == frameq_tail then the queue is empty.  Thus a full queue must only hold (FRAME_QUEUE_SIZE - 1) frames.
    int frameq_head;
    // The mutex protects writes to .frameq_head
    pthread_mutex_t mutex;
    pthread_cond_t not_empty_cond;

    // Note: this should only be modified by decoders_thread, and is not protected by the above lock.  It's "protected" by VideoState's .decoders_mutex, but that's really just there to allow the use of its .decoders_cond to signal when the decoder thread needs to wake up and decode a new packet (and also when it needs to handle e.g. seeking or pausing).
    int frameq_tail;
}
@end;

int decoder_init(VidPlayerDecoder *d, AVCodecContext *avctx, AVStream *stream);
void decoder_destroy(VidPlayerDecoder *d);

bool decoder_frameq_is_full(VidPlayerDecoder *d);

void decoder_flush(VidPlayerDecoder *d);
bool decoder_finished(VidPlayerDecoder *d, int current_serial);

bool decoder_send_packet(VidPlayerDecoder *d, AVPacket *pkt);
bool decoder_receive_frame(VidPlayerDecoder *d, int pkt_serial, VideoState *mov);

void decoder_advance_frame_already_locked(VidPlayerDecoder *d, VideoState *mov);
void decoder_advance_frame(VidPlayerDecoder *d, VideoState *mov);
Frame *decoder_peek_current_frame_already_locked(VidPlayerDecoder *d, VideoState *mov);
Frame *decoder_peek_current_frame(VidPlayerDecoder *d, VideoState *mov);
Frame *decoder_peek_next_frame(VidPlayerDecoder *d);
Frame *decoder_peek_current_frame_blocking_already_locked(VidPlayerDecoder *d, VideoState *mov);
