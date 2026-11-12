// LichessClient.m

#import "LichessClient.h"
#import <Security/Security.h>

static NSString *const kBaseURL = @"https://lichess.org";
static NSString *const kKeychainService = @"nl.yf.chess.lichess";
static NSString *const kFallbackKey = @"lichessTokenFallback";

static NSString *FormEncode(NSDictionary *form) {
    NSMutableCharacterSet *allowed = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
    [allowed addCharactersInString:@"-._~"];
    NSMutableArray *parts = [NSMutableArray array];
    for (NSString *key in form) {
        NSString *value = [NSString stringWithFormat:@"%@", form[key]];
        NSString *k = [key stringByAddingPercentEncodingWithAllowedCharacters:allowed];
        NSString *v = [value stringByAddingPercentEncodingWithAllowedCharacters:allowed];
        [parts addObject:[NSString stringWithFormat:@"%@=%@", k, v]];
    }
    return [parts componentsJoinedByString:@"&"];
}

static NSString *ErrorFromBody(NSData *data, NSInteger status) {
    if (data.length) {
        id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if ([json isKindOfClass:[NSDictionary class]]) {
            id err = json[@"error"];
            if ([err isKindOfClass:[NSString class]]) return err;
            if ([err isKindOfClass:[NSDictionary class]]) {
                NSMutableArray *msgs = [NSMutableArray array];
                for (id k in err) {
                    id v = err[k];
                    [msgs addObject:[v isKindOfClass:[NSArray class]] ? [v componentsJoinedByString:@" "] : [v description]];
                }
                if (msgs.count) return [msgs componentsJoinedByString:@" "];
            }
        }
    }
    if (status == 401) return @"Het token klopt niet of is verlopen. Log opnieuw in.";
    if (status == 403) return @"Het token mag dit niet. Maak een token met de rechten 'board:play' en 'challenge:write'.";
    if (status == 429) return @"Te veel aanvragen. Wacht een minuut en probeer het opnieuw.";
    return [NSString stringWithFormat:@"Lichess gaf foutcode %ld.", (long)status];
}

#pragma mark - Stream

@implementation LichessStream {
    NSURLSession *_session;
    NSURLSessionDataTask *_task;
    NSMutableData *_buffer;
    NSMutableData *_errorBody;
    NSInteger _status;
    BOOL _cancelled;
}

- (void)startWithRequest:(NSURLRequest *)request {
    _buffer = [NSMutableData data];
    _errorBody = [NSMutableData data];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    // Lichess stuurt regelmatig een lege regel om de verbinding open te houden.
    config.timeoutIntervalForRequest = 90;
    config.timeoutIntervalForResource = 24 * 3600;
    _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    _task = [_session dataTaskWithRequest:request];
    [_task resume];
}

- (void)cancel {
    _cancelled = YES;
    self.onLine = nil;
    self.onEnd = nil;
    [_task cancel];
    [_session invalidateAndCancel];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) _status = ((NSHTTPURLResponse *)response).statusCode;
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    if (_cancelled) return;
    if (_status != 200) {
        [_errorBody appendData:data];
        return;
    }
    [_buffer appendData:data];
    while (YES) {
        const char *bytes = (const char *)_buffer.bytes;
        NSUInteger len = _buffer.length;
        const char *nl = len ? memchr(bytes, '\n', len) : NULL;
        if (!nl) break;
        NSUInteger lineLen = (NSUInteger)(nl - bytes);
        NSData *line = [_buffer subdataWithRange:NSMakeRange(0, lineLen)];
        [_buffer replaceBytesInRange:NSMakeRange(0, lineLen + 1) withBytes:NULL length:0];
        if (line.length == 0) continue;
        id obj = [NSJSONSerialization JSONObjectWithData:line options:0 error:nil];
        if ([obj isKindOfClass:[NSDictionary class]] && self.onLine) self.onLine(obj);
        if (_cancelled) return;
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (!_cancelled) {
        NSString *text = nil;
        if (error) text = [LichessClient describeError:error];
        else if (_status != 200) text = ErrorFromBody(_errorBody, _status);
        void (^end)(NSInteger, NSString *) = self.onEnd;
        self.onLine = nil;
        self.onEnd = nil;
        if (end) end(_status, text);
    }
    [_session finishTasksAndInvalidate];
}

@end

#pragma mark - Client

@implementation LichessClient

+ (instancetype)shared {
    static LichessClient *c = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        c = [[LichessClient alloc] init];
        [c loadToken];
    });
    return c;
}

- (NSDictionary *)keychainQuery {
    return @{ (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
              (__bridge id)kSecAttrService: kKeychainService,
              (__bridge id)kSecAttrAccount: @"token" };
}

- (void)loadToken {
    NSMutableDictionary *q = [[self keychainQuery] mutableCopy];
    q[(__bridge id)kSecReturnData] = @YES;
    q[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;
    CFTypeRef result = NULL;
    OSStatus st = SecItemCopyMatching((__bridge CFDictionaryRef)q, &result);
    if (st == errSecSuccess && result) {
        NSData *data = (__bridge_transfer NSData *)result;
        _token = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    if (!_token.length) {
        // Zonder ondertekening werkt de sleutelhanger soms niet; dan staat het token hier.
        _token = [[NSUserDefaults standardUserDefaults] stringForKey:kFallbackKey];
    }
}

- (BOOL)hasToken {
    return _token.length > 0;
}

- (void)saveToken:(NSString *)token {
    token = [token stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    _token = token;
    _username = nil;
    _userId = nil;
    SecItemDelete((__bridge CFDictionaryRef)[self keychainQuery]);
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kFallbackKey];
    if (!token.length) return;
    NSMutableDictionary *add = [[self keychainQuery] mutableCopy];
    add[(__bridge id)kSecValueData] = [token dataUsingEncoding:NSUTF8StringEncoding];
    add[(__bridge id)kSecAttrAccessible] = (__bridge id)kSecAttrAccessibleAfterFirstUnlock;
    OSStatus st = SecItemAdd((__bridge CFDictionaryRef)add, NULL);
    if (st != errSecSuccess) {
        [[NSUserDefaults standardUserDefaults] setObject:token forKey:kFallbackKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)logout {
    [self saveToken:@""];
    _token = nil;
}

- (NSMutableURLRequest *)requestFor:(NSString *)method path:(NSString *)path form:(NSDictionary *)form accept:(NSString *)accept {
    NSURL *url = [NSURL URLWithString:[kBaseURL stringByAppendingString:path]];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    req.HTTPMethod = method;
    req.timeoutInterval = 30;
    [req setValue:accept forHTTPHeaderField:@"Accept"];
    [req setValue:@"YFSchaak/1.2 (iOS)" forHTTPHeaderField:@"User-Agent"];
    if (_token.length) [req setValue:[@"Bearer " stringByAppendingString:_token] forHTTPHeaderField:@"Authorization"];
    if (form) {
        [req setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        req.HTTPBody = [FormEncode(form) dataUsingEncoding:NSUTF8StringEncoding];
    } else if ([method isEqualToString:@"POST"]) {
        req.HTTPBody = [NSData data];
    }
    return req;
}

- (void)request:(NSString *)method path:(NSString *)path form:(NSDictionary *)form
     completion:(void (^)(NSInteger, id, NSString *))completion {
    NSMutableURLRequest *req = [self requestFor:method path:path form:form accept:@"application/json"];
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:req
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            NSInteger status = [response isKindOfClass:[NSHTTPURLResponse class]] ? ((NSHTTPURLResponse *)response).statusCode : 0;
            id json = data.length ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
            NSString *text = nil;
            if (error) text = [LichessClient describeError:error];
            else if (status < 200 || status >= 300) text = ErrorFromBody(data, status);
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(status, json, text);
            });
        }];
    [task resume];
}

- (void)publicRequest:(NSString *)path
           completion:(void (^)(NSInteger, id, NSString *))completion {
    NSString *saved = _token;
    _token = nil;   // zonder token versturen
    NSMutableURLRequest *req = [self requestFor:@"GET" path:path form:nil accept:@"application/json"];
    _token = saved;
    req.timeoutInterval = 45;
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:req
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            NSInteger status = [response isKindOfClass:[NSHTTPURLResponse class]] ? ((NSHTTPURLResponse *)response).statusCode : 0;
            id json = data.length ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
            NSString *text = nil;
            if (error) text = [LichessClient describeError:error];
            else if (status < 200 || status >= 300) text = ErrorFromBody(data, status);
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(status, json, text);
            });
        }];
    [task resume];
}

- (LichessStream *)streamPath:(NSString *)path method:(NSString *)method form:(NSDictionary *)form
                       onLine:(void (^)(NSDictionary *))onLine
                        onEnd:(void (^)(NSInteger, NSString *))onEnd {
    NSMutableURLRequest *req = [self requestFor:method path:path form:form accept:@"application/x-ndjson"];
    req.timeoutInterval = 90;
    LichessStream *s = [[LichessStream alloc] init];
    s.onLine = onLine;
    s.onEnd = onEnd;
    [s startWithRequest:req];
    return s;
}

+ (NSString *)describeError:(NSError *)error {
    if ([error.domain isEqualToString:NSURLErrorDomain]) {
        switch (error.code) {
            case NSURLErrorNotConnectedToInternet:
            case NSURLErrorNetworkConnectionLost:
                return @"Geen internetverbinding. Controleer je wifi.";
            case NSURLErrorTimedOut:
                return @"Lichess reageert niet (time-out). Probeer het opnieuw.";
            case NSURLErrorCannotFindHost:
            case NSURLErrorCannotConnectToHost:
            case NSURLErrorDNSLookupFailed:
                return @"Kan lichess.org niet bereiken.";
            case NSURLErrorSecureConnectionFailed:
            case NSURLErrorServerCertificateUntrusted:
            case NSURLErrorServerCertificateHasUnknownRoot:
            case NSURLErrorServerCertificateHasBadDate:
            case NSURLErrorServerCertificateNotYetValid:
                return @"De beveiligde verbinding met lichess.org lukt niet. Klopt de datum en tijd op je iPad?";
            case NSURLErrorCancelled:
                return @"Geannuleerd.";
            default:
                break;
        }
    }
    return [NSString stringWithFormat:@"Verbindingsfout: %@", error.localizedDescription];
}

@end
