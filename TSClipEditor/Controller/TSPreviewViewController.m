//
//  TSPreviewViewController.m
//  TSClipEditor
//
//  Created by Antelis on 2018/7/13.
//  Copyright © 2018 shion. All rights reserved.
//

#import "TSPreviewViewController.h"
#import <libVidPlayer/VidPlayerView.h>

@interface TSPreviewViewController ()
@property(nonatomic, strong) NSTimer *timer;
@property(nonatomic,weak) IBOutlet VidPlayerView *vidView;
@property(nonatomic,weak) IBOutlet NSTextField *vidTick;
@property(nonatomic,weak) IBOutlet NSButton *vidPlay;
@property(nonatomic) VidPlayerVideo *video;
@property(nonatomic) float previewStart;
@property(nonatomic) float preview;
@property(nonatomic) float previewEnd;
@end

@implementation TSPreviewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}
- (IBAction)playPause:(id)sender{
    NSButton *btn = (NSButton *)sender;
    if (_video) {
        if (_video.paused) {
            _video.paused = NO;
            _video.playbackSpeedPercent = 100;
            [btn setImage:[NSImage imageNamed:@"pause"]];
        } else {
            _video.paused = YES;
            [btn setImage:[NSImage imageNamed:@"pplay"]];
        }
    }
}
- (void)loadVideoWithURL:(NSURL *)url start:(float)start end:(float)end {
    if (url) {
        
        _video = [[VidPlayerVideo alloc] initWithURL:url error:nil];
        [_vidView setVideo: _video];


        _previewEnd = (self.video.durationInMicroseconds/1000000.0)*end;
        _previewStart = (self.video.durationInMicroseconds/1000000.0)*start;
        
        self.vidTick.stringValue = [NSString stringWithFormat:@"%.0f",_previewStart];
        [self startTimer];
        self.video.currentTimeAsFraction = start;
        self.video.paused = NO;
        [self.vidPlay setImage:[NSImage imageNamed:@"pause"]];
        
    }
}
-(void) startTimer {
    _timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(updatePos:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
}

-(void) stopTimer {
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
}
-(void) updatePos:(NSTimer*)theTimer {
    if (_video.paused) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        //float t = self.video.currentTimeAsFraction;
        
        self.vidTick.stringValue = [NSString stringWithFormat:@"%.0f",self.previewStart];
        if (self.previewStart > self.previewEnd){
            self.video.paused = true;
            
        }
        self.previewStart += 0.5;
    });
    
}
- (void)viewWillDisappear {
    _video.paused = true;
    [self stopTimer];
}
@end
