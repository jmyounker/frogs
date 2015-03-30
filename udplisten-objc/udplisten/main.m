//
//  main.m
//  udplistener
//
//  Created by Jeff Younker on 3/26/15.
//  Copyright (c) 2015 Jeff Younker. All rights reserved.
//

#import "UDPListen.h"

#include <netdb.h>

#pragma mark * Utilities

#pragma mark * Main

@interface Main : NSObject <UDPListenDelegate>
- (BOOL)runServerOnPort:(NSUInteger)port;
@end

@interface Main ()
@property (nonatomic, strong, readwrite) UDPListen *      echo;
@end

@implementation Main

@synthesize echo      = _echo;

- (void)dealloc
{
    [self->_echo stop];
}

- (BOOL)runServerOnPort:(NSUInteger)port
// This creates a UDPListen object and runs it in server mode.
{
    assert(self.echo == nil);
    
    self.echo = [[UDPListen alloc] init];
    assert(self.echo != nil);
    
    self.echo.delegate = self;
    
    [self.echo startServerOnPort:port];
    
    while (self.echo != nil) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
    
    // The loop above is supposed to run forever.  If it doesn't, something must
    // have failed and we want main to return EXIT_FAILURE.
    
    return NO;
}

- (void)echo:(UDPListen *)echo didReceiveData:(NSData *)data fromAddress:(NSData *)addr
// This UDPListen delegate method is called after successfully receiving data.
{
    assert(echo == self.echo);
#pragma unused(echo)
    assert(data != nil);
    assert(addr != nil);
    NSLog(@"received data");
}

- (void)echo:(UDPListen *)echo didReceiveError:(NSError *)error
// This UDPListen delegate method is called after a failure to receive data.
{
    assert(echo == self.echo);
#pragma unused(echo)
    assert(error != nil);
    NSLog(@"received error");
}

- (void)echo:(UDPListen *)echo didStartWithAddress:(NSData *)address
// This UDPListen delegate method is called after the object has successfully started up.
{
    assert(echo == self.echo);
#pragma unused(echo)
    assert(address != nil);
    NSLog(@"receiving");
}

- (void)echo:(UDPListen *)echo didStopWithError:(NSError *)error
// This UDPListen delegate method is called after the object stops spontaneously.
{
    assert(echo == self.echo);
#pragma unused(echo)
    assert(error != nil);
    NSLog(@"failed with error");
    self.echo = nil;
}

@end

int main(int argc, char **argv)
{
#pragma unused(argc)
#pragma unused(argv)
    BOOL                success;
    Main *              mainObj;
    int                 port;
    
    @autoreleasepool {
        success = YES;
        port = 7868;
        mainObj = [[Main alloc] init];
        assert(mainObj != nil);
                    
        success = [mainObj runServerOnPort:(NSUInteger) port];
    }
    if (success) {
        return EXIT_FAILURE;
    } else {
        return EXIT_SUCCESS;
    }
}

//#import <Foundation/Foundation.h>
//
//int main(int argc, const char * argv[]) {
//    @autoreleasepool {
//        // insert code here...
//        NSLog(@"Hello, World!");
//    }
//    return 0;
//}
