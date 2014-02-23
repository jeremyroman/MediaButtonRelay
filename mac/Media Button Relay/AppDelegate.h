#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

- (IBAction)installPerUser:(id)sender;
- (IBAction)installSystem:(id)sender;
- (IBAction)launchWebStore:(id)sender;

@property (assign) IBOutlet NSWindow *window;

@end
