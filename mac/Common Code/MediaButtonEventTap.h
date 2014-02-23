#import <Foundation/Foundation.h>

#define kMediaButtonPlayPause @"playPause"
#define kMediaButtonPrevious @"previous"
#define kMediaButtonNext @"next"

@class MediaButtonEventTap;

@protocol MediaButtonEventTapDelegate
- (void)mediaButtonEventTap:(MediaButtonEventTap*)tap didInterceptMediaButton:(NSString*)buttonName;
@end

@interface MediaButtonEventTap : NSObject

- (id)init;
- (void)dealloc;
- (void)start;
// TODO: Consider implementing |stop|. Currently this is stopped by ending the process.

@property (atomic, readwrite, weak) id<MediaButtonEventTapDelegate> delegate;

@end
