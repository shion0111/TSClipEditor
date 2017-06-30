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

static AVFormatContext *fmt_ctx;
static AVCodecParameters *pCodecPar;

static AVStream *vStream;
int videoStream;
AVCodec *pCodec;
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
void cleanContext(){
    
    if (fmt_ctx != NULL)
    {
        avformat_free_context(fmt_ctx);
        fmt_ctx = NULL;
    }
    
}
#pragma mark - open a ts file and get duration
int getVideoDurationWithLoc(const char* fileLoc)
{
    AVCodecContext *pCodecCtx = NULL;
    if (pCodecCtx != NULL)
        avcodec_free_context(&pCodecCtx);
    
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
    
    videoStream = av_find_best_stream(fmt_ctx , AVMEDIA_TYPE_VIDEO, -1, -1, &pCodec, 0);
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

CGImageRef imageFromAVPicture(AVFrame *pict, int width, int height)
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
    
    pCodecPar =fmt_ctx->streams[videoStream]->codecpar;
    AVCodecContext *pCodecCtx = NULL;
    pCodecCtx = avcodec_alloc_context3(NULL);
    int res = avcodec_parameters_to_context(pCodecCtx,pCodecPar);
    if (res < 0) return NULL;
    
    // Find the decoder for the video stream
    //=avcodec_find_decoder(pCodecCtx->codec_id);
    // Open video codec
    if (avcodec_open2(pCodecCtx, pCodec,NULL) < 0)
    {
        avformat_free_context(fmt_ctx);
        fprintf(stderr, "unable to open codec");
        return NULL;
    }
    
    //ImageSize finalSize = get_new_frame_size(pCodecCtx->width, pCodecCtx->height, request.width, request.height);
    
    //vStream->need_parsing = AVSTREAM_PARSE_TIMESTAMPS;
    
    AVFrame* frame = av_frame_alloc();
    AVPacket packet;
    int frame_end = 0;
    //int64_t second = 2;
    int width = pCodecCtx->width,height = pCodecCtx->height;
    second = floor(second);
    
    if (avStream_seek(second) <0)
    {
        fprintf(stderr, "Seek on invalid time");
        return NULL;
    }
    
    avcodec_flush_buffers(pCodecCtx);
    //int64_t ss = 0;
    while (!frame_end && (av_read_frame(fmt_ctx, &packet) >= 0))
    {
        if (packet.stream_index == videoStream)
        {
            //ss = avcodec_decode_video2(pCodecCtx, frame, &frame_end, &packet);
            
            
            int ret;
            
            //ss = 0;
            
            //if (pkt)
            {
                ret = avcodec_send_packet(pCodecCtx, &packet);
                // In particular, we don't expect AVERROR(EAGAIN), because we read all
                // decoded frames with avcodec_receive_frame() until done.
                if (ret < 0)
                    return NULL;//ret == AVERROR_EOF ? 0 : ret;
            }
            
            ret = avcodec_receive_frame(pCodecCtx, frame);
            if (ret < 0 && ret != AVERROR(EAGAIN) && ret != AVERROR_EOF)
                return NULL;
            if (ret >= 0)
            {
                frame_end = 1;
                break;
            }
            //return 0;
            
            
        }
        //av_free_packet(&packet);
    }
    //NSLog(@"packet dts %ld/%ld (%ld)",(unsigned long)packet.dts,(unsigned long)packet.pts,(unsigned long)ss);
    fprintf(stderr, "frame found %lf\n",second);
    av_seek_frame(fmt_ctx, videoStream, 0, AVSEEK_FLAG_BYTE);
    avcodec_flush_buffers(pCodecCtx);
    
    AVFrame *sized = NULL;
    if(frame)
    {
        sized = resize_frame(pCodecCtx, frame,width/2,height/2);
        av_free(frame);
    }
    
    CGImageRef thumb = imageFromAVPicture(sized, width/2, height/2);
    
    
    avcodec_free_context(&pCodecCtx);
    av_free(sized);
    return thumb;
    
}
