// LichessClient.h
// YF Schaak - verbinding met lichess.org (online spelen via de officiële Board API).
// Inloggen gaat met een persoonlijk API-token dat je op lichess.org maakt.

#import <Foundation/Foundation.h>

// Een open verbinding die regel voor regel JSON stuurt (ndjson).
@interface LichessStream : NSObject <NSURLSessionDataDelegate>
@property (nonatomic, copy) void (^onLine)(NSDictionary *obj);
@property (nonatomic, copy) void (^onEnd)(NSInteger status, NSString *errorText);
- (void)cancel;
@end

@interface LichessClient : NSObject

+ (instancetype)shared;

@property (nonatomic, readonly) NSString *token;
@property (nonatomic, copy) NSString *username;   // na controle van het token
@property (nonatomic, copy) NSString *userId;     // kleine letters

- (BOOL)hasToken;
- (void)saveToken:(NSString *)token;
- (void)logout;

// Gewone aanvraag. json is NSDictionary/NSArray of nil.
- (void)request:(NSString *)method path:(NSString *)path form:(NSDictionary *)form
     completion:(void (^)(NSInteger status, id json, NSString *errorText))completion;

// Aanvraag zonder inloggen (openbare gegevens, bijv. puzzels).
- (void)publicRequest:(NSString *)path
           completion:(void (^)(NSInteger status, id json, NSString *errorText))completion;

// Doorlopende verbinding (bijv. /api/stream/event).
- (LichessStream *)streamPath:(NSString *)path method:(NSString *)method form:(NSDictionary *)form
                       onLine:(void (^)(NSDictionary *obj))onLine
                        onEnd:(void (^)(NSInteger status, NSString *errorText))onEnd;

// Leesbare Nederlandse foutmelding bij een netwerkfout.
+ (NSString *)describeError:(NSError *)error;

@end
