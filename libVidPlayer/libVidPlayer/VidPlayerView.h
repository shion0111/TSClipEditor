//
//  VidPlayerView.h
//  libVidPlayer
//
//  Created by Antelis on 2017/8/12.
//  Copyright © 2017 Antelis. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VidPlayerLayer.h"
#import "VidPlayerVideo.h"

@interface VidPlayerView : NSView
{
    VidPlayerLayer* _videoLayer;
}

-(void) setMovie:(VidPlayerVideo *)movie;

@end
