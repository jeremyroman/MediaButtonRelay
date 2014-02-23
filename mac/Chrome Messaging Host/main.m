#import <Foundation/Foundation.h>

#import "ChromeMessagingHost.h"

int main(int argc, const char * argv[])
{
    @autoreleasepool {
        ChromeMessagingHost *host = [[ChromeMessagingHost alloc] init];
        [host start];
        CFRunLoopRun();
    }
    // Unreachable.
    return EXIT_FAILURE;
}

