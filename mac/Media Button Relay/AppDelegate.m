#import "AppDelegate.h"

#import "PrivilegedFileWriter.h"

@interface AppDelegate ()
- (NSDictionary*)manifestData;
- (void)showError:(NSError*)error;
@end

@implementation AppDelegate

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

- (IBAction)installPerUser:(id)sender
{
    NSArray *supportPaths =
        NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    assert([supportPaths count] > 0);
    NSString *manifestDir =
        [supportPaths[0] stringByAppendingPathComponent:@"Google/Chrome/NativeMessagingHosts"];
    NSString *manifestPath =
        [[manifestDir stringByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier]]
         stringByAppendingPathExtension:@"json"];

    NSError *error = nil;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:manifestDir
                                   withIntermediateDirectories:YES
                                                    attributes:nil
                                                         error:&error]) {
        [self showError:error];
        return;
    }

    NSData *json = [NSJSONSerialization dataWithJSONObject:[self manifestData]
                                                   options:0
                                                     error:&error];
    if (error != nil) {
        [self showError:error];
        return;
    }

    if (![json writeToFile:manifestPath options:NSDataWritingAtomic error:&error]) {
        [self showError:error];
        return;
    }

    NSAlert *alert = [NSAlert alertWithMessageText:@"Native messaging host manifest created."
                                     defaultButton:nil
                                   alternateButton:nil
                                       otherButton:nil
                         informativeTextWithFormat:@""];
    [alert beginSheetModalForWindow:self.window
                  completionHandler:^(NSModalResponse returnCode) {}];
}

- (IBAction)installSystem:(id)sender
{
    NSArray *libraryPaths =
        NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSLocalDomainMask, YES);
    assert([libraryPaths count] > 0);
    NSString *manifestDir =
        [libraryPaths[0] stringByAppendingPathComponent:@"Google/Chrome/NativeMessagingHosts"];
    NSString *manifestPath =
        [[manifestDir stringByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier]]
         stringByAppendingPathExtension:@"json"];

    NSError *error = nil;
    NSData *json = [NSJSONSerialization dataWithJSONObject:[self manifestData]
                                                   options:0
                                                     error:&error];
    if (error != nil) {
        [self showError:error];
        return;
    }

    if (![PrivilegedFileWriter writeData:json toFilePath:manifestPath]) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"Unable to create manifest."
                                         defaultButton:nil
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:@""];
        [alert beginSheetModalForWindow:self.window
                      completionHandler:^(NSModalResponse returnCode) {}];
        return;
    }

    NSAlert *alert = [NSAlert alertWithMessageText:@"Native messaging host manifest created."
                                     defaultButton:nil
                                   alternateButton:nil
                                       otherButton:nil
                         informativeTextWithFormat:@""];
    [alert beginSheetModalForWindow:self.window
                  completionHandler:^(NSModalResponse returnCode) {}];
}

- (IBAction)launchWebStore:(id)sender
{
    NSString *extensionID = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"ChromeExtensionID"];
    NSString *url =
        [NSString stringWithFormat:@"https://chrome.google.com/webstore/detail/%@", extensionID];

    if (![[NSWorkspace sharedWorkspace] openURLs:@[[NSURL URLWithString:url]]
                         withAppBundleIdentifier:@"com.google.Chrome"
                                         options:NSWorkspaceLaunchWithErrorPresentation
                  additionalEventParamDescriptor:nil
                               launchIdentifiers:NULL]) {

        NSAlert *alert = [NSAlert alertWithMessageText:@"Unable to launch Google Chrome."
                                         defaultButton:nil
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:@""];
        [alert beginSheetModalForWindow:self.window
                      completionHandler:^(NSModalResponse returnCode) {}];

    }
}

- (NSDictionary*)manifestData
{
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *extensionID = [bundle objectForInfoDictionaryKey:@"ChromeExtensionID"];
    NSString *origin = [NSString stringWithFormat:@"chrome-extension://%@/", extensionID];
    return @{@"name": [bundle bundleIdentifier],
             @"description": [bundle objectForInfoDictionaryKey:@"CFBundleName"],
             @"path": [bundle pathForAuxiliaryExecutable:@"Chrome Messaging Host"],
             @"type": @"stdio",
             @"allowed_origins": @[origin]};
}

- (void)showError:(NSError*)error
{
    NSAlert *alert = [NSAlert alertWithError:error];
    [alert beginSheetModalForWindow:self.window
                  completionHandler:^(NSModalResponse returnCode) {}];
}

@end
