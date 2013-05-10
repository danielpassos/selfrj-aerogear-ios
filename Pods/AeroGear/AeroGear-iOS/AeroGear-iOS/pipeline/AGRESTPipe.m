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

#import "AGRESTPipe.h"
#import "AGAuthenticationModuleAdapter.h"

#import "AGHttpClient.h"

//category:
#import "AGNSMutableArray+Paging.h"

@implementation AGRESTPipe {
    // TODO make properties on a PRIVATE category...
    id<AGAuthenticationModuleAdapter> _authModule;
    NSString* _recordId;
    AGPipeConfiguration* _config;
    // the state of the paging object reference.
    NSMutableArray* _pagingObject;
}

// =====================================================
// ================ public API (AGPipe) ================
// =====================================================

@synthesize type = _type;
@synthesize URL = _URL;

// ==============================================
// ======== 'factory' and 'init' section ========
// ==============================================

+(id) pipeWithConfig:(id<AGPipeConfig>) pipeConfig {
    return [[self alloc] initWithConfig:pipeConfig];
}

-(id) initWithConfig:(id<AGPipeConfig>) pipeConfig {
    self = [super init];
    if (self) {
        _type = @"REST";
        
        // set all the things:
        _config = (AGPipeConfiguration*) pipeConfig;
        
        NSURL* baseURL = _config.baseURL;
        NSString* endpoint = _config.endpoint;
        // append the endpoint/name and use it as the final URL
        NSURL* finalURL = [self appendEndpoint:endpoint toURL:baseURL];
        
        _URL = finalURL;
        _recordId = _config.recordId;
        _authModule = (id<AGAuthenticationModuleAdapter>) _config.authModule;
        
        _restClient = [AGHttpClient clientFor:finalURL timeout:_config.timeout];
        _restClient.parameterEncoding = AFJSONParameterEncoding;

        _pagingObject = [NSMutableArray array];
    }
    return self;
}

// private helper to append the endpoint
-(NSURL*) appendEndpoint:(NSString*)endpoint toURL:(NSURL*)baseURL {
    if (endpoint == nil) {
        endpoint = @"";
    }

    // append the endpoint name and use it as the final URL
    return [baseURL URLByAppendingPathComponent:endpoint];
}

// =====================================================
// ======== public API (AGPipe) ========
// =====================================================

-(void) read:(id)value
     success:(void (^)(id responseObject))success
     failure:(void (^)(NSError *error))failure {
    
    if (value == nil || [value isKindOfClass:[NSNull class]]) {
        [self raiseError:@"read" msg:@"read id value was nil" failure:failure];
        // do nothing
        return;
    }
    
    // try to add auth.token:
    [self applyAuthToken];
    
    NSString* objectKey = [self getStringValue:value];
    [_restClient getPath:[self appendObjectPath:objectKey] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        if (success) {
            //TODO: NSLog(@"Invoking successblock....");
            success(responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        if (failure) {
            //TODO: NSLog(@"Invoking failure block....");
            failure(error);
        }
    }];
}

// read all, via HTTP GET
-(void) read:(void (^)(id responseObject))success
     failure:(void (^)(NSError *error))failure {
    
    // try to add auth.token:
    [self applyAuthToken];
    
    // TODO: better Endpoints....
    [_restClient getPath:_URL.path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        if (success) {
            //TODO: NSLog(@"Invoking successblock....");
            success(responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        if (failure) {
            //TODO: NSLog(@"Invoking failure block....");
            failure(error);
        }
    } ];
}

// read, with (filter/query) params. Used for paging, can be used
// to issue queries as well...
-(void) readWithParams:(NSDictionary*)parameterProvider
               success:(void (^)(id responseObject))success
               failure:(void (^)(NSError *error))failure {

    // try to add auth.token:
    [self applyAuthToken];

    // if none has been passed, we use the "global" setting
    // which can be the default limit/offset OR what has
    // been configured on the PIPE level.....:
    if (!parameterProvider)
        parameterProvider = _config.parameterProvider;

    [_restClient getPath:_URL.path parameters:parameterProvider success:^(AFHTTPRequestOperation *operation, id responseObject) {

        NSDictionary *linkInformationContainer;
        if ([_config.metadataLocation isEqualToString:@"webLinking"]) {
            linkInformationContainer = [self parseWebLinkInformation:[[[operation response] allHeaderFields] valueForKey:@"Link"]];
        } else if ([_config.metadataLocation isEqualToString:@"body"]) {
            // if the response is an array, the parser returns nil
            linkInformationContainer = [self parseQueryInformation:responseObject];
        } else if ([_config.metadataLocation isEqualToString:@"header"]) {
            linkInformationContainer = [self parseQueryInformation:[[operation response] allHeaderFields]];
        }
        
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            [_pagingObject setArray:[NSArray arrayWithObject:responseObject]];
        } else {
            [_pagingObject setArray:(NSMutableArray*) responseObject];
        }
        
        // stash pipe reference:
        _pagingObject.pipe = self;
        // stash the SCROLLING params:
        _pagingObject.parameterProvider = linkInformationContainer;
        
        if (success) {
            //TODO: NSLog(@"Invoking successblock....");
            success(_pagingObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        if (failure) {
            //TODO: NSLog(@"Invoking failure block....");
            failure(error);
        }
    } ];
}


-(void) save:(NSDictionary*) object
     success:(void (^)(id responseObject))success
     failure:(void (^)(NSError *error))failure {
    
    // when null is provided we try to invoke the failure block
    if (object == nil || [object isKindOfClass:[NSNull class]]) {
        [self raiseError:@"save" msg:@"object was nil" failure:failure];
        // do nothing
        return;
    }
    
    // try to add auth.token:
    [self applyAuthToken];
    
    // Does a PUT or POST based on the fact if the object
    // already exists (if there is an 'id').
    
    // the blocks are unique to PUT and POST, so let's define them up-front:
    id successCallback = ^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            //TODO: NSLog(@"Invoking successblock....");
            success(responseObject);
        }
    };
    
    id failureCallback = ^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            //TODO: NSLog(@"Invoking failure block....");
            failure(error);
        }
    };
    
    id objectKey = [object objectForKey:_recordId];
    
    // we need to check if the map representation contains the "recordID" and its value is actually set:
    if (objectKey == nil || [objectKey isKindOfClass:[NSNull class]]) {
        //TODO: NSLog(@"HTTP POST to create the given object");
        [_restClient postPath:_URL.path parameters:object success:successCallback failure:failureCallback];
        return;
    } else {
        NSString* updateId = [self getStringValue:objectKey];
        //TODO: NSLog(@"HTTP PUT to update the given object");
        [_restClient putPath:[self appendObjectPath:updateId] parameters:object success:successCallback failure:failureCallback];
        return;
    }
}

-(void) remove:(NSDictionary*) object
       success:(void (^)(id responseObject))success
       failure:(void (^)(NSError *error))failure {
    
    // when null is provided we try to invoke the failure block
    if (object == nil || [object isKindOfClass:[NSNull class]]) {
        [self raiseError:@"remove" msg:@"object was nil" failure:failure];
        // do nothing
        return;
    }
    
    // try to add auth.token:
    [self applyAuthToken];
    
    id objectKey = [object objectForKey:_recordId];
    // we need to check if the map representation contains the "recordID" and its value is actually set:
    if (objectKey == nil || [objectKey isKindOfClass:[NSNull class]]) {
        [self raiseError:@"remove" msg:@"recordId not set" failure:failure];
        // do nothing
        return;
    }
    
    NSString* deleteKey = [self getStringValue:objectKey];
    
    [_restClient deletePath:[self appendObjectPath:deleteKey] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        if (success) {
            //TODO: NSLog(@"Invoking successblock....");
            success(responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        if (failure) {
            //TODO: NSLog(@"Invoking failure block....");
            failure(error);
        }
    } ];
}

-(void) cancel {
    // cancel all running http operations
    [_restClient.operationQueue cancelAllOperations];
}

// extract the sting value (e.g. for read:id, or remove:id)
-(NSString *) getStringValue:(id) value {
    NSString* objectKey;
    if ([value isKindOfClass:[NSString class]]) {
        objectKey = value;
    } else {
        objectKey = [value stringValue];
    }
    return objectKey;
}

// appends the path for delete/updates to the URL
-(NSString*) appendObjectPath:(NSString*)path {
    return [NSString stringWithFormat:@"%@/%@", _URL, path];
}

// helper method:
-(void) applyAuthToken {
    if ([_authModule isAuthenticated]) {
        [_restClient setDefaultHeader:@"Auth-Token" value:[_authModule authToken]];
    }
}

-(NSString *) description {
    return [NSString stringWithFormat: @"%@ [type=%@, url=%@]", self.class, _type, _URL];
}

-(void) raiseError:(NSString*) domain
               msg:(NSString*) msg
           failure:(void (^)(NSError *error))failure {
    
    if (!failure)
        return;
    
    NSError* error = [NSError errorWithDomain:[NSString stringWithFormat:@"org.aerogear.pipes.%@", domain]
                                         code:0
                                     userInfo:[NSDictionary dictionaryWithObjectsAndKeys:msg,
                                               NSLocalizedDescriptionKey, nil]];
    
    failure(error);
}

-(NSDictionary *) parseQueryInformation:(NSDictionary *)info {
    // NSArray is ONLY being passed in, when the metadataLocation is "body"
    // AND it is actually NOT at the root level, like twitter does
    if (!info || ![info isKindOfClass:[NSDictionary class]] || (info.count ==0)) {
        // for now... return NIL, since we do not support that...
        return nil;
    }

    NSString *nextIdentifier = _config.nextIdentifier;
    NSString *prevIdentifier = _config.previousIdentifier;

    // buld the MAP of links....:
    NSMutableDictionary *mapOfLink = [NSMutableDictionary dictionary];

    if ([info valueForKey:nextIdentifier] != nil)
        [mapOfLink setValue:[self transformQueryString:[info valueForKey:nextIdentifier]] forKey:@"AG-next-key"]; /// internal key...
    if ([info valueForKey:prevIdentifier] !=nil )
        [mapOfLink setValue:[self transformQueryString:[info valueForKey:prevIdentifier]] forKey:@"AG-prev-key"]; /// internal key...

    return mapOfLink;
}

-(NSDictionary *) parseWebLinkInformation:(NSString *)headerValue {
    NSMutableDictionary *pagingLinks = [NSMutableDictionary dictionary];
    NSArray *links = [headerValue componentsSeparatedByString:@","];
    for (NSString *link in links) {
        NSArray *elementsPerLink = [link componentsSeparatedByString:@";"];
        
        NSDictionary *queryArguments;
        for (NSString *elem in elementsPerLink) {
            NSString *tmpElem = [elem stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if ([tmpElem hasPrefix:@"<"] && [tmpElem hasSuffix:@">"]) {
                NSURL *parsedURL = [NSURL URLWithString:[[tmpElem substringFromIndex:1] substringToIndex:tmpElem.length-2]]; //2 because, the first did already cut one char...
                queryArguments = [self transformQueryString:parsedURL.query];
            } else if ([tmpElem hasPrefix:@"rel="]) {
                // only those 'rel' links that we need (prev/next)
                NSString *rel = [[tmpElem substringFromIndex:5] substringToIndex:tmpElem.length-6]; // cutting 5 + the last....
                
                if ([_config.nextIdentifier isEqualToString:rel]) {
                    [pagingLinks setValue:queryArguments forKey:@"AG-next-key"]; // internal key
                } else if ([_config.previousIdentifier isEqualToString:rel]) {
                    [pagingLinks setValue:queryArguments forKey:@"AG-prev-key"]; // internal key
                }
            } else {
                // ignore title etc
            }
        }
    }
    return pagingLinks;
}

-(NSDictionary *) transformQueryString:(NSString *) value {
    // we need to get rid of the '?' and everything before that
    // linke any URL info... (resource?params...)
    NSRange range = [value rangeOfString:@"?"];
    
    if (range.location != NSNotFound) {
        value = [value substringFromIndex:NSMaxRange(range)];
    }
    // chop the query string into a dictionary
    NSArray *components = [value componentsSeparatedByString:@"&"];
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    for (NSString *component in components) {
        [parameters setObject:[[component componentsSeparatedByString:@"="] objectAtIndex:1] forKey:[[component componentsSeparatedByString:@"="] objectAtIndex:0]];
    }
    return parameters;
}

+ (BOOL) accepts:(NSString *) type {
    return [type isEqualToString:@"REST"];
}

@end