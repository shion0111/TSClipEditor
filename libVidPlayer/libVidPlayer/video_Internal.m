//
//  video_internal.m
//  libVidPlayer
//
//  Created by Antelis on 2017/8/14.
//  Copyright © 2017 Antelis. All rights reserved.
//

#import "VideoState.h"
#import "VidPlayerDecoder.h"


void vp_if_new_video_frame_is_available_then_run(VideoState *mov, void (^func)(AVFrame *))
{
    int64_t now = clock_get_usec(mov);

    pthread_mutex_lock(&mov->viddec->mutex);

    Frame *fr = NULL;
    // Note: the loop generally takes ~1ms which is plenty fast enough with us being called every ~16ms.
    for (;;) {
        fr = decoder_peek_current_frame_already_locked(mov->viddec, mov);
        if (!fr) break;

        // If we've just seeked we want a new frame up ASAP (the clock comes from the first audio frame, which sometimes has a pts a little before that of the first video frame).
        if (fr->frm_serial != mov->last_shown_frame_serial) break;

        // If fr is still in the future don't show it yet (and we'll carry on showing the one already uploaded into a GL texture).
        if (now < fr->frm_pts_usec) {
            fr = NULL;
            break;
        }

        // If there's a later frame that we should already have shown or be showing then skip the earlier one.
        // xxx Maybe we should add a threshold to this, since if we've only overshot by a little bit it might be better to show a slightly stale frame for the sake of smoother playback in scenes with a lot of motion?
        Frame *next = decoder_peek_next_frame(mov->viddec);
        if (!next) break;
        if (now < next->frm_pts_usec) break;
        decoder_advance_frame_already_locked(mov->viddec, mov);
    }

    if (fr) {
        func(fr->frm_frame);
        mov->last_shown_frame_serial = fr->frm_serial;
        decoder_advance_frame_already_locked(mov->viddec, mov);
    }

    pthread_mutex_unlock(&mov->viddec->mutex);
}
