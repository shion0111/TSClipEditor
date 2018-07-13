//
//  TSPreviewViewController.h
//  TSClipEditor
//
//  Created by Antelis on 2018/7/13.
//  Copyright © 2018 shion. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface TSPreviewViewController : NSViewController
- (void)loadVideoWithURL:(NSURL *)url start:(int)start end:(int)end;
@end

NS_ASSUME_NONNULL_END
