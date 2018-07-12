//
//  VidPlayerVideo.h
//  libVidPlayer
//
//  Created by Antelis on 2017/8/13.
//  Copyright © 2017 Antelis. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class VideoState;
@protocol VidPlayerVideoOutput;

@interface VidPlayerVideo : NSObject {
@private
    VideoState *mov;
}

@property (retain, readonly) NSURL *url;

@property (readonly) NSSize naturalSize;
@property (readonly) int64_t durationInMicroseconds;
@property (assign) int64_t currentTimeInMicroseconds;

// How far along we are in playing the movie.  0.0 for the start, and 1.0 for the end.
@property (assign) double currentTimeAsFraction;

// Movies start out paused.  Set this to start/stop playing.
@property bool paused;

// Normally 100.  Adjust this to play faster or slower.  Pausing is separate from speed, i.e. if accessed while paused this returns the speed that will be used if playback were resumed.  This is an integer percentage (rather than a double fraction) to make accumulated rounding errors impossible.
@property (assign) int playbackSpeedPercent;

// Normally 100.  This is an integer percentage (rather than a float fraction) to make accumulated rounding errors impossible.
@property (assign) int volumePercent;

-(instancetype) initWithURL:(NSURL *)url error:(NSError **)errorPtr NS_DESIGNATED_INITIALIZER;

// Typically an VidPlayerLayer should be passed to this.  It's used to start/stop updating when paused/unpaused (so the layer doesn't waste tons of CPU), and also to explicitly update if seeking while paused.  The argument is held as a weak reference.
-(void) setOutput:(id<VidPlayerVideoOutput>)output;

-(void) invalidate;
@end



@protocol VidPlayerVideoOutput

// Called e.g. after seeking while paused.
-(void) movieOutputNeedsSingleUpdate;
// Called when playback starts or stops for any reason.
-(void) movieOutputNeedsContinuousUpdating:(bool)continuousUpdating;

@end;
