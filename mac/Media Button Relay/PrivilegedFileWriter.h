#import <Foundation/Foundation.h>

@interface PrivilegedFileWriter : NSObject

+ (BOOL)writeData:(NSData*)data toFilePath:(NSString*)path;

@end
