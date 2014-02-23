#import "PrivilegedFileWriter.h"

#import <Security/Authorization.h>
#import <sys/wait.h>

@implementation PrivilegedFileWriter

+ (BOOL)writeData:(NSData*)data toFilePath:(NSString*)path createDirectory:(BOOL)makeDir
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

    AuthorizationItem authItems[] = {
        {rightCStr, 0, NULL, 0},
        {kAuthorizationRightExecute, 0, NULL, 0}
    };

    AuthorizationRights rights;
    rights.count = sizeof authItems / sizeof authItems[0];
    rights.items = authItems;

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

    // We might have to create the directory.
    // Unfortunately, authopen won't do this for us.
    // |AuthorizationExecuteWithPrivileges| is deprecated, but it's also convenient.
    // Yes, this is improper, but it's a lot smaller than a dedicated helper just for this.
    // Especially if you have to do all the setuid-mangling stuff the docs ask for.
    NSString *directoryPath = [path stringByDeletingLastPathComponent];
    if (makeDir && ![[NSFileManager defaultManager] fileExistsAtPath:directoryPath]) {
        char dirCStr[PATH_MAX];
        NSUInteger dirNameLength = [directoryPath lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        assert(dirNameLength > 0 && dirNameLength < PATH_MAX - 1);
        strncpy(dirCStr, [directoryPath UTF8String], sizeof dirCStr);
        char *args[] = {"-p", dirCStr, NULL};
        status = AuthorizationExecuteWithPrivileges(authRef, "/bin/mkdir",
                                                    kAuthorizationFlagDefaults, args, NULL);
        if (status != errAuthorizationSuccess) {
            AuthorizationFree(authRef, kAuthorizationFlagDefaults);
            return NO;
        }

        // This should be the only child process, if any.
        // Would be nice if AuthorizationExecuteWithPrivileges could tell us this.
        int mkdirStatus;
        pid_t mkdirPid;
        while ((mkdirPid = wait(&mkdirStatus)) == -1 && errno == EINTR);
        if (!(mkdirPid == -1 && errno == ECHILD) &&
            !(mkdirPid > 0 && WIFEXITED(mkdirStatus) && WEXITSTATUS(mkdirStatus) == 0)) {
            AuthorizationFree(authRef, kAuthorizationFlagDefaults);
            return NO;
        }
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
