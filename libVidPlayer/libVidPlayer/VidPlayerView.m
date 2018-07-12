//
//  VidPlayerView.m
//  libVidPlayer
//
//  Created by Antelis on 2017/8/12.
//  Copyright © 2017 Antelis. All rights reserved.
//

#import "VidPlayerView.h"

@implementation VidPlayerView

-(void) setMovie:(VidPlayerVideo *)movie {
    if(!_videoLayer) {
        [self setWantsLayer:YES];
        CALayer *rootLayer = self.layer;
        rootLayer.needsDisplayOnBoundsChange = YES;
        
        _videoLayer = [VidPlayerLayer layer];
        CGSize frz = rootLayer.frame.size;
        _videoLayer.frame = NSMakeRect(0, 0, frz.width, frz.height);//rootLayer.frame;
        _videoLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
        _videoLayer.backgroundColor = CGColorGetConstantColor(kCGColorBlack);
        
        [rootLayer addSublayer:_videoLayer];
    }
    _videoLayer.movie = movie;
}

@end
