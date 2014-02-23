#import "ChromeMessagingHost.h"

@interface ChromeMessagingHost ()
- (void)postMessage:(id)message;
@property (atomic, readwrite, strong) MediaButtonEventTap* eventTap;
@property (atomic, readwrite, strong) NSFileHandle* outputHandle;
@end

@implementation ChromeMessagingHost

- (id)init {
    return [self initWithOutputHandle:[NSFileHandle fileHandleWithStandardOutput]];
}

- (id)initWithOutputHandle:(NSFileHandle*)outputHandle
{
    if ((self = [super init])) {
        self.eventTap = [[MediaButtonEventTap alloc] init];
        if (self.eventTap == nil) return nil;
        self.eventTap.delegate = self;
        self.outputHandle = outputHandle;
    }
    return self;
}

- (void)start
{
    [self.eventTap start];
}

- (void)postMessage:(id)message
{
    NSError* error = nil;
    NSData *json = [NSJSONSerialization dataWithJSONObject:message
                                                   options:0
                                                     error:&error];
    assert(error == nil);
    assert([json length] <= INT32_MAX);
    int32_t length = (int32_t) [json length];
    [self.outputHandle writeData:[NSData dataWithBytes:&length length:4]];
    [self.outputHandle writeData:json];
}

- (void)mediaButtonEventTap:(MediaButtonEventTap*)tap didInterceptMediaButton:(NSString*)buttonName
{
    [self postMessage:@{@"button": buttonName}];
}

@end
