//
//  VidPlayerMLayer.h
//  libVidPlayer
//
//  Created by Antelis on 2018/7/12.
//  Copyright © 2018 Antelis. All rights reserved.
//

//  Metal baked video layer //

#import <QuartzCore/QuartzCore.h>
#import <Cocoa/Cocoa.h>
#import "VidPlayerVideo.h"

NS_ASSUME_NONNULL_BEGIN

@interface VidPlayerMLayer : CAMetalLayer  <VidPlayerVideoOutput>
{
    VidPlayerVideo *_movie;
    
}
@property (retain) VidPlayerVideo *movie;

@end

NS_ASSUME_NONNULL_END
