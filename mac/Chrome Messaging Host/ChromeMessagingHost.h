#import <Foundation/Foundation.h>
#import "MediaButtonEventTap.h"

@interface ChromeMessagingHost : NSObject<MediaButtonEventTapDelegate>
- (id)init;
- (id)initWithOutputHandle:(NSFileHandle*)outputHandle;
- (void)start;
- (void)mediaButtonEventTap:(MediaButtonEventTap*)tap didInterceptMediaButton:(NSString*)buttonName;
@end
