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
#import "AGPipe.h"

/**
The library has built-in paging support, enabling the scrolling to either forward or backwards through a result set returned from the server. Paging metadata located in the server response (either in the headers by [webLinking](http://tools.ietf.org/html/rfc5988) or custom headers, or in the body) are used to identify the _next_ or the _previous_ result set. For example, in Twitter case, paging metadata are located in the body of the response, using _"next\_page"_ or _"previous\_page"_ to identify the next or previous result set respectively. The location of this metadata as well as naming, is fully configurable during the creation of the [Pipe](AGPipe), thus enabling greater flexibility in supporting several different paging strategies.

Below is an example that goes against the AeroGear Controller Server:

    NSURL* baseURL = [NSURL URLWithString:@"https://controller-aerogear.rhcloud.com/aerogear-controller-demo"];
    AGPipeline* agPipeline = [AGPipeline pipelineWithBaseURL:baseURL];
    
    id<AGPipe> cars = [agPipeline pipe:^(id<AGPipeConfig> config) {
        [config setName:@"cars-custom"];
        [config setNextIdentifier:@"AG-Links-Next"];
        [config setPreviousIdentifier:@"AG-Links-Previous"];
        [config setMetadataLocation:@"header"];
    }];

First we create our [Pipeline](AGPipeline) object. Notice that in the Pipe configuration object, we explicitely declare the name of the paging identifiers supported by the server, as well as the the location of these identifiers in the response. Note that If not specified, the library will assume the server is using Web Linking paging strategy.

## Start Paging

To kick-start pagination, you use the method ```readWithParams``` of the underlying [Pipe](AGPipe), passing your desired query parameters to the server. Upon successfully completion, the _pagedResultSet_ (an enchached category of NSArray) will allow you to scroll through the result set.

    __block NSMutableArray *pagedResultSet;

    // fetch the first page
    [cars readWithParams:@{@"color" : @"black", @"offset" : @"0", @"limit" : @1} success:^(id responseObject) {
        pagedResultSet = responseObject;

        // do something

    } failure:^(NSError *error) {
        //handle error
    }];

## Move Forward in the result set

To move forward in the result set, you simple call ```next``` on the _pagedResultSet_ :

    // move to the next page
    [pagedResultSet next:^(id responseObject) {
        // do something

    } failure:^(NSError *error) {
        // handle error
    }];

## Move Backwards in the result set

To move backwards in the result set, you simple call ```previous``` on the _pagedResultSet_ :

    [pagedResultSet previous:^(id responseObject) {
        // do something
        
    } failure:^(NSError *error) {
        // handle error
    }];

## Exception cases

Moving beyond last or first page is left on the behaviour of the specific server implementation, that is the library will not treat it differently. Some servers can throw an error (like Twitter or AeroGear Controller does) by respondng with an http error response, or simply return an empty list. The user is responsible to cater for exception cases like this.
*/
@interface NSMutableArray (AGPaging)

// yes, these props. are a bit ugly:
@property id<AGPipe> pipe;
@property NSDictionary* parameterProvider;

/**
 * Reads the next 'page', based on the current position of the paging result from the server.
 *
 * @param success A block object to be executed when the request operation finishes successfully.
 * This block has no return value and takes one argument: The object created from the response
 * data of request.
 *
 * @param failure A block object to be executed when the request operation finishes unsuccessfully,
 * or that finishes successfully, but encountered an error while parsing the resonse data.
 * This block has no return value and takes one argument: The `NSError` object describing
 * the network or parsing error that occurred.
 */
-(void) next:(void (^)(id responseObject))success
     failure:(void (^)(NSError *error))failure;

/**
 * Reads the previous 'page', based on the current position of the paging result from the server.
 *
 * @param success A block object to be executed when the request operation finishes successfully.
 * This block has no return value and takes one argument: The object created from the response
 * data of request.
 *
 * @param failure A block object to be executed when the request operation finishes unsuccessfully,
 * or that finishes successfully, but encountered an error while parsing the resonse data.
 * This block has no return value and takes one argument: The `NSError` object describing
 * the network or parsing error that occurred.
 */
-(void) previous:(void (^)(id responseObject))success
         failure:(void (^)(NSError *error))failure;


@end
