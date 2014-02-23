#import "PrivilegedFileWriter.h"

#import <Security/Authorization.h>

@implementation PrivilegedFileWriter

+ (BOOL)writeData:(NSData*)data toFilePath:(NSString*)path
{
    // Create the requested right as a C string.
    NSString* right = [@"sys.openfile.readwritecreate." stringByAppendingString:path];
    NSUInteger encodedLength = [right lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    char rightCStr[PATH_MAX + 32];
    if (encodedLength == 0 || encodedLength > (sizeof rightCStr) - 1) {
        NSLog(@"Massive path passed to PrivilegedFileWriter. Failing.");
        return NO;
    }
    strncpy(rightCStr, [right UTF8String], sizeof rightCStr);

    AuthorizationItem authItem;
    authItem.name = rightCStr;
    authItem.value = NULL;
    authItem.valueLength = 0;
    authItem.flags = 0;

    AuthorizationRights rights;
    rights.count = 1;
    rights.items = &authItem;

    AuthorizationFlags flags = kAuthorizationFlagDefaults |
                               kAuthorizationFlagInteractionAllowed |
                               kAuthorizationFlagExtendRights |
                               kAuthorizationFlagPreAuthorize;

    AuthorizationRef authRef;
    OSStatus status;
    status = AuthorizationCreate(&rights, kAuthorizationEmptyEnvironment, flags, &authRef);
    if (status != errAuthorizationSuccess) {
        return NO;
    }

    AuthorizationExternalForm authExternal;
    status = AuthorizationMakeExternalForm(authRef, &authExternal);
    if (status != errAuthorizationSuccess) {
        AuthorizationFree(authRef, kAuthorizationFlagDefaults);
        return NO;
    }

    NSPipe *pipe = [NSPipe pipe];
    NSFileHandle *handle = [pipe fileHandleForWriting];
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/libexec/authopen"];
    [task setArguments:@[@"-extauth", @"-c", @"-w", path]];
    [task setStandardInput:pipe];
    [task launch];
    [handle writeData:[NSData dataWithBytes:&authExternal length:sizeof authExternal]];
    [handle writeData:data];
    [handle closeFile];
    [task waitUntilExit];

    AuthorizationFree(authRef, kAuthorizationFlagDefaults);
    return [task terminationStatus] == 0;
}

@end
