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

#import <Foundation/Foundation.h>
#import "AGConfig.h"
#import "AGAuthenticationModule.h"

/**
 * Represents the public API to configure AGPipe objects.
 */
@protocol AGPipeConfig <AGConfig>

/**
 * The baseURL to the configuration.
 */
@property (strong, nonatomic) NSURL* baseURL;

/**
 * The endpoint to the configuration.
 * If no endpoint is specified, the name will be used as its value.
 */
@property (copy, nonatomic) NSString* endpoint;

/**
 * The recordId to the configuration.
 */
@property (copy, nonatomic) NSString* recordId;

/**
 * A dictionary containing all the HTTP request parameters and their values,
 * that are passed to the server, used used when issuing paging requests.
 *
 * If no "parameter provider" has been provided, the values for
 * limit/offset are used
 */
@property (copy, nonatomic) NSDictionary* parameterProvider;

/**
 * The offset of the first element that should be included in the
 * returned collection (default: 0)
 * 
 * If a paramater provider has been given, the offset value is ignored.
 */
@property (copy, nonatomic) NSString* offset;

/**
 * The maximum number of results the server should return (default: 10)
 *
 * If a paramater provider has been given, the limit value is ignored.
 */
@property (assign, nonatomic) NSNumber* limit;

/**
 * Indicates whether paging information (see identifiers) is received
 * from the response 'header', the response 'body' or via RFC 5988 ('webLinking'),
 * which is the default. Other values are ignored and the default is being used.
 */
@property (copy, nonatomic) NSString* metadataLocation;

/**
 * The next identifier name (default: 'next').
 */
@property (copy, nonatomic) NSString* nextIdentifier;

/**
 * The previous identifier name (default: 'previous').
sb */
@property (copy, nonatomic) NSString* previousIdentifier;

/**
 * The AGAuthenticationModule object to the configuration.
 */
@property (strong, nonatomic) id<AGAuthenticationModule> authModule;

/**
 * The timeout interval for a request to complete.
 */
@property (assign, nonatomic) NSTimeInterval timeout;

@end
