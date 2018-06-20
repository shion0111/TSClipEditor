//
//  ffmpeg.c
//  TSClipEditor
//
//  Created by Antelis on 26/06/2017.
//  Copyright © 2017 shion. All rights reserved.
//

#include "ffmpeg.h"
#import <libavformat/avformat.h>
#import <libavutil/dict.h>
#import <libavcodec/avcodec.h>
#import <libavutil/opt.h>
#import <libswscale/swscale.h>
#import <libavutil/mathematics.h>
#import <libavutil/imgutils.h>
#import <libavutil/error.h>
#import <libavutil/common.h>
#include <libavutil/timestamp.h>
#include <libavformat/avformat.h>

static AVFormatContext *fmt_ctx = NULL;

static AVStream *vStream;
int videoStream;

AVCodecContext *pCodecCtx = NULL;

static double theDuration;


void print_err(int ret) {
    fprintf(stderr,"😭 err: %s\n", av_err2str(ret));
}

const char * strFromErr(int ret) {
    return av_err2str(ret);
}

int is_eof(int ret) {
    return ret == AVERROR_EOF;
}

int err2averr(int ret) {
    return AVERROR(ret);
}

int64_t initial_timestamp()
{
    
    if ( fmt_ctx->start_time != AV_NOPTS_VALUE && fmt_ctx->start_time > 0 )
        return fmt_ctx->start_time;
    else
        return 0;
}
void cleanVideoContext(){
    
    if (pCodecCtx != NULL){
        avcodec_close(pCodecCtx);
        avcodec_free_context(&pCodecCtx);
        pCodecCtx = NULL;
    }
    
    if (fmt_ctx != NULL)
    {
        avformat_close_input(&fmt_ctx);
        avformat_free_context(fmt_ctx);
        fmt_ctx = NULL;
    }
    
}
#pragma mark - open a ts file and get duration
int getVideoDurationWithLoc(const char* fileLoc)
{
    cleanVideoContext();
    
    AVDictionaryEntry *tag = NULL;
    int ret;
    
    
    av_register_all();
    if ((ret = avformat_open_input(&fmt_ctx, fileLoc, NULL, NULL)))
        return 0;
    
    
    ret = avformat_find_stream_info(fmt_ctx,NULL);
    
    while ((tag = av_dict_get(fmt_ctx->metadata, "", tag, AV_DICT_IGNORE_SUFFIX)))
        printf("%s=%s\n", tag->key, tag->value);
    
    
    theDuration = fmt_ctx->duration;
    double dd = theDuration / AV_TIME_BASE;
    printf("duration = %lf,%lf \n", theDuration,dd);
    
    //AVCodec *sCodec = NULL;
    //int sub = av_find_best_stream(fmt_ctx, AVMEDIA_TYPE_SUBTITLE, -1, -1, &sCodec, 0);
    
    videoStream = av_find_best_stream(fmt_ctx , AVMEDIA_TYPE_VIDEO, -1, -1, NULL, 0);
    vStream = fmt_ctx->streams[videoStream];
    
    dd = (double) vStream->duration /  (double)vStream->time_base.den;
    
    int intValue = (int)(dd < 0 ? dd - 0.5 : dd + 0.5);
    
    
    return intValue;
}
#pragma mark - seek video to a certain frame based on time
int avStream_seek(double frac)
{
    
    int res;
    
    
    if ( frac > 0. )
    {
        
        int64_t pos = frac*AV_TIME_BASE+initial_timestamp();
        res = avformat_seek_file( fmt_ctx, -1, pos - 1 * AV_TIME_BASE, pos, pos+1*AV_TIME_BASE, AVSEEK_FLAG_BACKWARD);
        if (res < 0)
        {
            //hb_error("avformat_seek_file failed");
            return -1;
        }
    }
    else
        
    {
        int64_t pos = initial_timestamp();
        res = avformat_seek_file( fmt_ctx, -1, INT64_MIN, pos, INT64_MAX, AVSEEK_FLAG_BACKWARD);
        if (res < 0)
        {
            //hb_error("avformat_seek_file failed");
            return -1;
        }
    }
    
    return 1;
}
#pragma mark -
AVFrame* resize_frame(AVCodecContext *codec_ctx, AVFrame *frame_av, double width, double height)
{
    uint8_t *Buffer;
    int     BufSiz;
    int     ImgFmt = AV_PIX_FMT_YUV420P;
    
    //Alloc frame
    BufSiz = av_image_get_buffer_size(AV_PIX_FMT_RGB24, codec_ctx->width, codec_ctx->height, 1);
    Buffer = (uint8_t *)calloc(BufSiz, sizeof(uint8_t));//apr_pcalloc(pool, BufSiz);
    
    AVFrame *frameRGB_av = av_frame_alloc();//av_frame_alloc();
    
    av_image_fill_arrays(frameRGB_av->data,frameRGB_av->linesize ,Buffer, AV_PIX_FMT_RGB24, codec_ctx->width, codec_ctx->height,1);
    
    
    //Resize frame
    struct SwsContext *image_ctx = sws_getContext(codec_ctx->width, codec_ctx->height,
                                                  ImgFmt, width, height, AV_PIX_FMT_RGB24, SWS_BICUBIC, NULL, NULL, NULL);
    
    sws_scale(image_ctx, (const uint8_t * const *) frame_av->data, frame_av->linesize, 0,
              codec_ctx->height, frameRGB_av->data, frameRGB_av->linesize);
    sws_freeContext(image_ctx);
    
    free(Buffer);
    
    
    
    return frameRGB_av;
}

CGImageRef imageFromAVFrame(AVFrame *pict, int width, int height)
{
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    //NSLog(@"imageFromAVP %d",(int)pict->data[1024]);
    CFDataRef data = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, pict->data[0], pict->linesize[0]*height,kCFAllocatorNull);
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGImageRef cgImage = CGImageCreate(width,
                                       height,
                                       8,
                                       24,
                                       pict->linesize[0],
                                       colorSpace,
                                       bitmapInfo,
                                       provider,
                                       NULL,
                                       false,
                                       kCGRenderingIntentDefault);
    CGColorSpaceRelease(colorSpace);
    CGDataProviderRelease(provider);
    CFRelease(data);
    
    return cgImage;
}
#pragma mark -
CGImageRef getVideoThumbAtPosition(double second)
{
    // initialize the decoder AVCodecContext
    if (pCodecCtx == NULL){
        AVCodecParameters *pCodecPar =fmt_ctx->streams[videoStream]->codecpar;
        pCodecCtx = avcodec_alloc_context3(NULL);
        int res = avcodec_parameters_to_context(pCodecCtx,pCodecPar);
        if (res < 0) return NULL;
        
        AVCodec *pCodec = NULL;
        // Open video codec
        // Find the decoder for the video stream
        pCodec = avcodec_find_decoder(pCodecCtx->codec_id);
        if (avcodec_open2(pCodecCtx, pCodec,NULL) < 0)
        {
            avformat_free_context(fmt_ctx);
            fprintf(stderr, "unable to open codec");
            return NULL;
        }
    }
    
    AVFrame* frame = av_frame_alloc();
    AVPacket packet;
    int frame_end = 0;
    int width = pCodecCtx->width,height = pCodecCtx->height;
    second = floor(second);
    
    if (avStream_seek(second) <0)
    {
        av_free(frame);
        fprintf(stderr, "Seek on invalid time");
        return NULL;
    }
    
    avcodec_flush_buffers(pCodecCtx);
    
    while (!frame_end && (av_read_frame(fmt_ctx, &packet) >= 0))
    {
        if (packet.stream_index == videoStream)
        {
            
            
            if (packet.buf == NULL) continue;
            
            int ret;
            
            ret = avcodec_send_packet(pCodecCtx, &packet);
                // In particular, we don't expect AVERROR(EAGAIN), because we read all
                // decoded frames with avcodec_receive_frame() until done.
            if (ret < 0){
                av_free(frame);
                return NULL;//ret == AVERROR_EOF ? 0 : ret;
                
            }
            
            ret = avcodec_receive_frame(pCodecCtx, frame);
            if (ret < 0 && ret != AVERROR(EAGAIN) && ret != AVERROR_EOF)
                return NULL;
            //else if (ret < 0)
            //    printf("avcodec_receive_frame error (%f): %d,%s \n",second,ret,av_err2str(ret));
            if (ret >= 0)
            {
                av_packet_unref(&packet);                
                frame_end = 1;
                break;
            }
            //return 0;
            
            
        }
        av_packet_unref(&packet);
    }
    //avcodec_flush_buffers(pCodecCtx);
    
    AVFrame *sized = NULL;
    if(frame)
    {
        sized = resize_frame(pCodecCtx, frame,width/4,height/4);
    }
    
    av_free(frame);
    CGImageRef thumb = imageFromAVFrame(sized, width/4, height/4);
    
    av_free(sized);
    return thumb;
    
}


static void log_packet(const AVFormatContext *fmt_ctx, const AVPacket *pkt, const char *tag)
{
    AVRational *time_base = &fmt_ctx->streams[pkt->stream_index]->time_base;
    
    printf("%s: pts:%s pts_time:%s dts:%s dts_time:%s duration:%s duration_time:%s stream_index:%d\n",
           tag,
           av_ts2str(pkt->pts), av_ts2timestr(pkt->pts, time_base),
           av_ts2str(pkt->dts), av_ts2timestr(pkt->dts, time_base),
           av_ts2str(pkt->duration), av_ts2timestr(pkt->duration, time_base),
           pkt->stream_index);
}


// get understood about swift function or obj-c function as a function pointer in c (block mechanism)
// test TS -> other container

// https://stackoverflow.com/questions/15157759/pass-instance-method-as-function-pointer-to-c-library
// directly porting to swift? (It's dirty!!!!)
int SaveClipWithInfo(float from_seconds, float end_seconds,const char* out_filename,const void *observer,
                     const CutClipProgressCallback progresscallback,
                     const CutClipFinishCallback finishcallback) {
    
    if (from_seconds < 0)
        from_seconds = 0;
    if (end_seconds > theDuration)
        end_seconds = theDuration;
    
    avcodec_flush_buffers(pCodecCtx);
    
    if (fmt_ctx == NULL) {
        fprintf(stderr, "The source file is not selected yet!\n");
        return  -1111;
    }
    
    int vstremindex = av_find_best_stream(fmt_ctx , AVMEDIA_TYPE_VIDEO, -1, -1, NULL, 0);
    
    AVOutputFormat *ofmt = NULL;
    AVFormatContext *ofmt_ctx = NULL;
    AVPacket pkt;
    int ret, i;
    /*
    if ((ret = avformat_find_stream_info(fmt_ctx, 0)) < 0) {
        fprintf(stderr, "Failed to retrieve input stream information\n");
        goto end;
    }
    */
    //av_dump_format(fmt_ctx, 0, in_filename, 0);
    
    avformat_alloc_output_context2(&ofmt_ctx, NULL, NULL, out_filename);
    if (!ofmt_ctx) {
        fprintf(stderr, "Could not create output context\n");
        ret = AVERROR_UNKNOWN;
        goto end;
    }
    
    ofmt = ofmt_ctx->oformat;
    
    for (i = 0; i < fmt_ctx->nb_streams; i++) {
        AVStream *in_stream = fmt_ctx->streams[i];
        
        AVCodec *pCodec = NULL;
        pCodec = avcodec_find_decoder(in_stream->codecpar->codec_id);
        AVStream *out_stream = avformat_new_stream(ofmt_ctx, pCodec);
        if (!out_stream) {
            fprintf(stderr, "Failed allocating output stream\n");
            ret = AVERROR_UNKNOWN;
            goto end;
        }
        
        AVCodecContext *pctx = avcodec_alloc_context3(NULL);
        ret = avcodec_parameters_to_context(pctx,in_stream->codecpar);
        if (ret < 0) {
            fprintf(stderr, "Could not retrieve source codec context\n");
            goto end;
        }
        
        pctx->codec_tag = 0;
        if (ofmt_ctx->oformat->flags & AVFMT_GLOBALHEADER) {
            pctx->flags |= CODEC_FLAG_GLOBAL_HEADER;
        }
        
        ret = avcodec_parameters_from_context(out_stream->codecpar, pctx);
        if (ret < 0) {
            printf("Failed to copy context input to output stream codec context\n");
            goto end;
        }
    }
    av_dump_format(ofmt_ctx, 0, out_filename, 1);
    
    //  open output
    if (!(ofmt->flags & AVFMT_NOFILE)) {
        ret = avio_open(&ofmt_ctx->pb, out_filename, AVIO_FLAG_WRITE);
        if (ret < 0) {
            fprintf(stderr, "Could not open output file '%s'", out_filename);
            goto end;
        }
    }
    
    // write header
    ret = avformat_write_header(ofmt_ctx, NULL);
    if (ret < 0) {
        fprintf(stderr, "Error occurred when opening output file\n");
        goto end;
    }
    
    
    //  seek to from_seconds
    //ret =av_seek_frame(fmt_ctx, -1, from_seconds*AV_TIME_BASE, AVSEEK_FLAG_ANY);
    int64_t pos = from_seconds*AV_TIME_BASE+initial_timestamp();
    ret = avformat_seek_file( fmt_ctx, -1, pos - 1 * AV_TIME_BASE, pos, pos+1*AV_TIME_BASE, AVSEEK_FLAG_BACKWARD);
    if (ret < 0) {
        fprintf(stderr, "Error seek\n");
        goto end;
    }
    
    int64_t *dts_start_from = malloc(sizeof(int64_t) * fmt_ctx->nb_streams);
    memset(dts_start_from, 0, sizeof(int64_t) * fmt_ctx->nb_streams);
    int64_t *pts_start_from = malloc(sizeof(int64_t) * fmt_ctx->nb_streams);
    memset(pts_start_from, 0, sizeof(int64_t) * fmt_ctx->nb_streams);
    
    int frame_count = 0;
    float current = 0.0;
    while (1) {
        AVStream *in_stream, *out_stream;
        
        ret = av_read_frame(fmt_ctx, &pkt);
        if (ret < 0)
            break;
        
        in_stream  = fmt_ctx->streams[pkt.stream_index];
        out_stream = ofmt_ctx->streams[pkt.stream_index];
        double base = av_q2d(in_stream->time_base);
        
        printf("pkt time: %lf,%lf",base,base * pkt.pts);
        
        log_packet(fmt_ctx, &pkt, "in");
        
        //  check if copy to the end_seconds
        if (pkt.stream_index == vstremindex) {
            current += pkt.duration*base;
            //if (base * pkt.pts > end_seconds) {
            if (current > (end_seconds - from_seconds)) {
                av_packet_unref(&pkt);
                ret = 0;
                break;
            }
        }
        
        if (dts_start_from[pkt.stream_index] == 0) {
            dts_start_from[pkt.stream_index] = pkt.dts;
            printf("dts_start_from: %s\n", av_ts2str(dts_start_from[pkt.stream_index]));
        }
        if (pts_start_from[pkt.stream_index] == 0) {
            pts_start_from[pkt.stream_index] = pkt.pts;
            printf("pts_start_from: %s\n", av_ts2str(pts_start_from[pkt.stream_index]));
        }
        
        /* copy packet */
        pkt.pts = av_rescale_q_rnd(pkt.pts - pts_start_from[pkt.stream_index], in_stream->time_base, out_stream->time_base, AV_ROUND_NEAR_INF|AV_ROUND_PASS_MINMAX);
        pkt.dts = av_rescale_q_rnd(pkt.dts - dts_start_from[pkt.stream_index], in_stream->time_base, out_stream->time_base, AV_ROUND_NEAR_INF|AV_ROUND_PASS_MINMAX);
        if (pkt.pts < 0) {
            pkt.pts = 0;
        }
        if (pkt.dts < 0) {
            pkt.dts = 0;
        }
        
        pkt.duration = (int)av_rescale_q((int64_t)pkt.duration, in_stream->time_base, out_stream->time_base);
        pkt.pos = -1;
        log_packet(ofmt_ctx, &pkt, "out");
        printf("\n");
        
        /*
         av_packet_rescale_ts(pkt, *time_base, st->time_base);
         pkt->stream_index = st->index;
         */
        ret = av_interleaved_write_frame(ofmt_ctx, &pkt);
        if (ret < 0) {
            fprintf(stderr, "Error muxing packet\n");
            break;
        }
        frame_count++;
        current += pkt.duration;
        //  progress callback here //
        progresscallback(observer,current, end_seconds-from_seconds);
        
        av_packet_unref(&pkt);
    }
    free(dts_start_from);
    free(pts_start_from);
    
    av_write_trailer(ofmt_ctx);
    
    
    //  finish callback here //
    finishcallback(observer);
end:
    
    //  source file should not be closed here for the scenario.
    //  avformat_close_input(&fmt_ctx);
    
    /* close output */
    if (ofmt_ctx && !(ofmt->flags & AVFMT_NOFILE))
        avio_closep(&ofmt_ctx->pb);
    avformat_free_context(ofmt_ctx);
    
    if (ret < 0 && ret != AVERROR_EOF) {
        fprintf(stderr, "Error occurred: %s\n", av_err2str(ret));
        return ret;
    }
    
    return 0;
    
}
