// This code is based on https://github.com/kbhomes/google-music-mac.

#import "MediaButtonEventTap.h"

#import <AppKit/AppKit.h>
#import <IOKit/hidsystem/ev_keymap.h>

@interface MediaButtonEventTap ()

- (void)runEventTapThread;

@property (atomic, readwrite) CFMachPortRef eventTap;
@property (atomic, readwrite) CFRunLoopSourceRef runLoopSource;

@end

static CGEventRef event_tap_callback(CGEventTapProxy proxy,
                                     CGEventType type,
                                     CGEventRef event,
                                     void* custom)
{
    MediaButtonEventTap *parent = (__bridge MediaButtonEventTap*) custom;

    // Why were we disabled? This may not be polite, but re-enable self.
    if (type == kCGEventTapDisabledByTimeout || type == kCGEventTapDisabledByUserInput) {
        CGEventTapEnable(parent.eventTap, true);
        return event;
    }

    // Ignore uninteresting events.
    if (type != NX_SYSDEFINED)
        return event;

    // Looking further. Use NSEvent to read remaining data.
    // TODO: figure out where some of these magic constants come from.
    NSEvent* nsEvent = [NSEvent eventWithCGEvent:event];
    if (nsEvent.type != NSSystemDefined || nsEvent.subtype != 8)
        return event;
    
    int keyCode = (nsEvent.data1 & 0xffff0000) >> 16;
    int keyFlags = nsEvent.data1 & 0x0000ffff;
    BOOL isKeyDown = ((keyFlags & 0xff00) >> 8) == 0xa;

    void (^callback)(NSString*) = ^(NSString* button) {
        if (!isKeyDown) return;
        dispatch_async(dispatch_get_main_queue(), ^{
            [parent.delegate mediaButtonEventTap:parent
                         didInterceptMediaButton:button];
        });
    };

    switch (keyCode) {
        case NX_KEYTYPE_PLAY:
            callback(kMediaButtonPlayPause);
            return NULL;
        case NX_KEYTYPE_NEXT:
        case NX_KEYTYPE_FAST:
            callback(kMediaButtonNext);
            return NULL;
        case NX_KEYTYPE_PREVIOUS:
        case NX_KEYTYPE_REWIND:
            callback(kMediaButtonPrevious);
            return NULL;
    }
    return event;
}

@implementation MediaButtonEventTap

@synthesize delegate;

- (id)init
{
    if ((self = [super init])) {
        self.eventTap = CGEventTapCreate(kCGSessionEventTap,
                                         kCGHeadInsertEventTap,
                                         kCGEventTapOptionDefault,
                                         CGEventMaskBit(NX_SYSDEFINED),
                                         event_tap_callback,
                                         (__bridge void*) self);
        if (!self.eventTap)
            return nil;
        
        self.runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault,
                                                           self.eventTap,
                                                           0 /* order */);
    }
    return self;
}

- (void)dealloc
{
    CFRelease(self.eventTap);
    self.eventTap = nil;
    CFRelease(self.runLoopSource);
    self.runLoopSource = nil;
}

- (void)start
{
    [NSThread detachNewThreadSelector:@selector(runEventTapThread)
                             toTarget:self
                           withObject:nil];
}

- (void)runEventTapThread
{
    CFRunLoopRef runLoop = CFRunLoopGetCurrent();
    CFRunLoopAddSource(runLoop, self.runLoopSource, kCFRunLoopCommonModes);

    CGEventTapEnable(self.eventTap, true);
    CFRunLoopRun();
    CGEventTapEnable(self.eventTap, false);
}

@end
