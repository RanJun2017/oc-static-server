//
//  StaticServer.m
//  hello_world-mobile
//
//  Created by Anne on 2018/1/23.
//

#import "StaticServer.h"

static StaticServer *staticserverInstance = nil;

@implementation StaticServer

+ (StaticServer *)sharedInstance {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        staticserverInstance = [[StaticServer alloc] init];
    });
    
    return staticserverInstance;
}

- (instancetype)init {
    if((self = [super init])) {
        [GCDWebServer self];
        _webServer = [[GCDWebServer alloc] init];
    }
    return self;
}

#pragma mark cocos
+ (NSString*)startServer:(NSString*)port optroot:(NSString*)optroot localOnly:(BOOL)localOnly keepAlive:(BOOL)keepAlive {
    NSString* url = [[StaticServer sharedInstance] start:port optroot:optroot localOnly:localOnly keepAlive:keepAlive];
    return url;
}
- (NSString*)start:(NSString*)port optroot:(NSString*)optroot localOnly:(BOOL)localhost_only keepAlive:(BOOL)keep_alive {
    NSString *root = [NSString stringWithFormat:@"%@/%@", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0], optroot ];
    if(root && [root length] > 0) {
        self.www_root = root;
    }
    
    if(port && [port length] > 0) {
        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
        f.numberStyle = NSNumberFormatterDecimalStyle;
        self.port = [f numberFromString:port];
    } else {
        self.port = [NSNumber numberWithInt:-1];
    }
    
    self.keep_alive = keep_alive;
    
    self.localhost_only = localhost_only;
    
    if(_webServer.isRunning != NO) {
        NSError *error = nil;
        NSLog(@"server_error StaticServer is already up: %@", error);
        return nil;
    }
    
    [_webServer addGETHandlerForBasePath:@"/" directoryPath:self.www_root indexFilename:@"index.html" cacheAge:3600 allowRangeRequests:YES];
    
    NSError *error;
    NSMutableDictionary* options = [NSMutableDictionary dictionary];
    
    
    NSLog(@"Started StaticServer on port %@", self.port);
    
    if (![self.port isEqualToNumber:[NSNumber numberWithInt:-1]]) {
        [options setObject:self.port forKey:GCDWebServerOption_Port];
    } else {
        [options setObject:[NSNumber numberWithInteger:8080] forKey:GCDWebServerOption_Port];
    }
    
    if (self.localhost_only == YES) {
        [options setObject:@(YES) forKey:GCDWebServerOption_BindToLocalhost];
    }
    
    if (self.keep_alive == YES) {
        [options setObject:@(NO) forKey:GCDWebServerOption_AutomaticallySuspendInBackground];
    }
    
    
    if([_webServer startWithOptions:options error:&error]) {
        NSNumber *listenPort = [NSNumber numberWithUnsignedInteger:_webServer.port];
        self.port = listenPort;
        self.url = [NSString stringWithFormat: @"%@://%@:%@", [_webServer.serverURL scheme], [_webServer.serverURL host], [_webServer.serverURL port]];
        NSLog(@"Started StaticServer at URL %@", self.url);
        return self.url;
    } else {
        NSLog(@"Error starting StaticServer: %@", error);
        return nil;
    }
}

#pragma mark stop;
+ (void)stopServer {
    [[StaticServer sharedInstance] stop];
}

- (void)stop {
    if(_webServer.isRunning == YES) {
        [_webServer stop];
        NSLog(@"StaticServer stopped");
    }
}
@end
