//
//  TSPreviewViewController.m
//  TSClipEditor
//
//  Created by Antelis on 2018/7/13.
//  Copyright © 2018 shion. All rights reserved.
//

#import "TSPreviewViewController.h"
#import <libVidPlayer/VidPlayerView.h>

@interface TSPreviewViewController (){
    NSTimer *timer;
}
@property(nonatomic,weak) IBOutlet VidPlayerView *vidView;
@property(nonatomic,weak) IBOutlet NSTextField *vidTick;
@property(nonatomic) VidPlayerVideo *video;
@property(nonatomic) int previewStart;
@property(nonatomic) int previewEnd;
@end

@implementation TSPreviewViewController
- (NSString *)formatTime:(int64_t) usec {
    int i = usec / 1000000;
//    int d = i / (24*60*60);
//    int h = (i - d * (24*60*60)) / (60*60);
//    int m = (i - d * (24*60*60) - h * (60*60)) / 60;
//    int s = (i - d * (24*60*60) - h * (60*60) - m * 60);
//    int f = (usec % 1000000) / 1000;
    return [NSString stringWithFormat:@"%d",i];//@"%02d:%02d:%02d:%03d", h, m, s, f];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}
- (IBAction)playPause:(id)sender{
    if (_video) {
        if (_video.paused) {
            _video.paused = NO;
            _video.playbackSpeedPercent = 100;
        } else {
            _video.paused = YES;
        }
    }
}
- (void)loadVideoWithURL:(NSURL *)url start:(int)start end:(int)end {
    if (url) {
        
        _video = [[VidPlayerVideo alloc] initWithURL:url error:nil];
        [_vidView setVideo: _video];
    
    
    if (_video) [self startTimer];
        _previewEnd = end;
        _previewStart = start;
        
        [self performSelector:@selector(deferShowVideo) withObject:nil afterDelay:0.5];
        
    }
}
- (void)deferShowVideo{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.vidView setVideo: self.video];
        self.video.currentTimeAsFraction = self.previewStart;
        self.video.paused = NO;

    });
}
-(void) startTimer {
    timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updatePos:) userInfo:nil repeats:YES];
}

-(void) stopTimer {
    if (timer) {
        [timer invalidate];
        timer = nil;
    }
}
-(void) updatePos:(NSTimer*)theTimer {
    int t = (int)_video.currentTimeAsFraction;
    
    _vidTick.stringValue = [self formatTime:_video.currentTimeInMicroseconds];
    if (t > self.previewEnd)
        _video.paused = true;
}
- (void)viewWillDisappear {
    _video.paused = true;
    [self stopTimer];
}
@end
