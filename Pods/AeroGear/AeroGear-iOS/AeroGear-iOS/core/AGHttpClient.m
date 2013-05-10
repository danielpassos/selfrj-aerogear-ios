/*
 * JBoss, Home of Professional Open Source.
 * Copyright Red Hat, Inc., and individual contributors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "AGHttpClient.h"

#import <objc/runtime.h>

// useful macro to check iOS version
#define SYSTEM_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

// -----------AFHTTPRequestOperation extension------------
// adds an associative reference to assign a timer with
// the operation. Will be used on success/failure callbacks
// to invalidate it.
@interface AFHTTPRequestOperation (Timeout)

// the timer associated with the operation
@property (nonatomic, retain) NSTimer* timer;

// override to invalidate the timer oncancel
-(void)cancel;
@end

static char const * const TimerTagKey = "TimerTagKey";

@implementation AFHTTPRequestOperation (Timeout)

@dynamic timer;

- (NSTimer*)timer {
    return objc_getAssociatedObject(self, TimerTagKey);
}

- (void)setTimer:(NSTimer*)timer {
    objc_setAssociatedObject(self, TimerTagKey, timer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(void)cancel {
    [super cancel];
    
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}
@end
// -------------------------------------------------------

@implementation AGHttpClient {
    // secs before a request timeouts (alternative name for primitive "double")
    NSTimeInterval _interval;
}

+ (AGHttpClient *)clientFor:(NSURL *)url {
    return [[self alloc] initWithBaseURL:url timeout:60 /* the default timeout interval */];
}

+ (AGHttpClient *)clientFor:(NSURL *)url timeout:(NSTimeInterval)interval {
    return [[self alloc] initWithBaseURL:url timeout:interval];
}

- (id)initWithBaseURL:(NSURL *)url timeout:(NSTimeInterval)interval {
	
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }
    
    // set the timeout interval for requests
    _interval = interval;
    
    [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
    
    // Accept HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
	[self setDefaultHeader:@"Accept" value:@"application/json"];
    
    return self;
}

// override to manual schedule a timeout event.
// This is because for version of iOS < 6, if the timeout interval(for POST requests)
// is less than 240 secs, the interval is ignored.
// see https://devforums.apple.com/thread/25282?start=0&tstart=0
- (void)postPath:(NSString *)path
      parameters:(NSDictionary *)parameters
         success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
         failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    
	NSURLRequest* request = [self requestWithMethod:@"POST" path:path parameters:parameters];
    
    [self processRequest:request success:success failure:failure];
}

// override to manual schedule a timeout event.
// This is because for version of iOS < 6, if the timeout interval(for PUT requests)
// is less than 240 secs, the interval is ignored.
// see https://devforums.apple.com/thread/25282?start=0&tstart=0
- (void)putPath:(NSString *)path
     parameters:(NSDictionary *)parameters
        success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
        failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    
	NSURLRequest* request = [self requestWithMethod:@"PUT" path:path parameters:parameters];
    
    [self processRequest:request success:success failure:failure];
}

// override to not handle the cookies and to add a request timeout interval
- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                      path:(NSString *)path
                                parameters:(NSDictionary *)parameters
{
    // invoke the 'requestWithMethod:path:parameters:' from AFNetworking:
    NSMutableURLRequest* req = [super requestWithMethod:method path:path parameters:parameters];
    
    // set the timeout interval
    [req setTimeoutInterval:_interval];
    
    // disable the default cookie handling in the override:
    [req setHTTPShouldHandleCookies:NO];
    
    return req;
}

// =====================================================
// =========== private utility methods  ================
// =====================================================

// Gateway of both postPath and putPath methods to schedule a POST/PUT http operation.
//
// This is needed, cause for those two requests, extra steps should be taken that
// will honour the timeout interval set in our AGPipeConfig (if running in versions of iOS < 6
// where the timeout interval less than 240sec is ignored)
//
// In particular for those versions we:
// - start a manual timer that upon fire (on request timeout) will invoke the client's failure block.
// - success/failure blocks are wrapped, so that the associative timer is invalidated upon
//   success or failure completion of the request.
-(void)processRequest:(NSURLRequest*)request
              success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
              failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    
    AFHTTPRequestOperation* operation;
    
    // check if the ios version honours the timeout bug
    if (SYSTEM_VERSION_LESS_THAN(@"6.0")) {
        operation = [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            // invalidate the timer associated with the operation
            [operation.timer invalidate];
            operation.timer = nil;
            
            success(operation, responseObject);
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            
            // invalidate the timer associated with the operation
            [operation.timer invalidate];
            operation.timer = nil;
            
            failure(operation, error);
        }];
        
        
        // the block to be executed when timeout occurs
        void (^timeout)(void) = ^ {
            // cancel operation
            [operation cancel];
            
            // the timer is invalidated after calling this block(a non-repeating timer)
            // nil out the operation timer instance var
            operation.timer = nil;
            
            // construct error
            NSError* error = [NSError errorWithDomain:NSURLErrorDomain
                                                 code:-1001
                                             userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"The request timed out.",
                                                       NSLocalizedDescriptionKey, nil]];
            // inform client
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(operation, error);
            });
        };
        
        // associate the timer and schedule to run
        operation.timer = [NSTimer scheduledTimerWithTimeInterval:_interval
                                                           target:[NSBlockOperation blockOperationWithBlock:timeout]
                                                         selector:@selector(main)
                                                         userInfo:nil
                                                          repeats:NO];
    } else {
        operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
    }
    
    [self enqueueHTTPRequestOperation:operation];
}

@end
