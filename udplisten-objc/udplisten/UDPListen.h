#import <Foundation/Foundation.h>

#if TARGET_OS_EMBEDDED || TARGET_IPHONE_SIMULATOR
#import <CFNetwork/CFNetwork.h>
#else
#import <CoreServices/CoreServices.h>
#endif

@protocol UDPListenDelegate;

@interface UDPListen : NSObject

- (id)init;

- (void)startServerOnPort:(NSUInteger)port;
// Starts an echo server on the specified port.  Will call the
// -echo:didStartWithAddress: delegate method on success and the
// -echo:didStopWithError: on failure.  After that, the various
// 'data' delegate methods may be called.

- (void)stop;
// Will stop the object, preventing any future network operations or delegate
// method calls until the next start call.

@property (nonatomic, weak,   readwrite) id<UDPListenDelegate>    delegate;
@property (nonatomic, assign, readonly, getter=isServer) BOOL   server;

@end

@protocol UDPListenDelegate <NSObject>

@optional

// In all cases an address is an NSData containing some form of (struct sockaddr),
// specifically a (struct sockaddr_in) or (struct sockaddr_in6).

- (void)echo:(UDPListen *)echo didReceiveData:(NSData *)data fromAddress:(NSData *)addr;
// Called after successfully receiving data.  On a server object this data will
// automatically be echoed back to the sender.
//
// assert(echo != nil);
// assert(data != nil);
// assert(addr != nil);

- (void)echo:(UDPListen *)echo didReceiveError:(NSError *)error;
// Called after a failure to receive data.
//
// assert(echo != nil);
// assert(error != nil);

- (void)echo:(UDPListen *)echo didSendData:(NSData *)data toAddress:(NSData *)addr;
// Called after successfully sending data.  On the server side this is typically
// the result of an echo.
//
// assert(echo != nil);
// assert(data != nil);
// assert(addr != nil);

- (void)echo:(UDPListen *)echo didFailToSendData:(NSData *)data toAddress:(NSData *)addr error:(NSError *)error;
// Called after a failure to send data.
//
// assert(echo != nil);
// assert(data != nil);
// assert(addr != nil);
// assert(error != nil);

- (void)echo:(UDPListen *)echo didStartWithAddress:(NSData *)address;
// Called after the object has successfully started up.  This is the local address
// to which the server is bound.
//
// assert(echo != nil);
// assert(address != nil);

- (void)echo:(UDPListen *)echo didStopWithError:(NSError *)error;
// Called after the object stops spontaneously (that is, after some sort of failure,
// but now after a call to -stop).
//
// assert(echo != nil);
// assert(error != nil);

@end