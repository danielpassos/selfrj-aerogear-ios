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
#import "AGPipeConfig.h"
#import "AGAuthenticationModule.h"

/**
 AGPipeline represents a 'collection' of server connections (aka [Pipes](AGPipe)). It provides a standard way to communicate with the server no matter the data format or transport expected. It contains some simple management APIs to create and remove [Pipe](AGPipe) objects.

 ## Creating a Pipeline and a Pipe object

 Below is an example that creates a Pipeline to AeroGear TODO server application and adds a [Pipe](AGPipe) to it, that points to the *projects* REST endpoint.

    NSString* baseURL = @"http://todo-aerogear.rhcloud.com/todo-server/";

    // create the 'todo' pipeline, which points to the baseURL of the REST application
    AGPipeline* todo = [AGPipeline pipelineWithBaseURL:[NSURL URLWithString:baseURL]];

    // Add a REST pipe for the 'projects' endpoint
    id<AGPipe> projects = [todo pipe:^(id<AGPipeConfig> config) {
        [config setName:@"projects"];
        [config setType:@"REST"]; // this is the default, can be emitted
    }];
 */
@interface AGPipeline : NSObject

/**
 * An initializer method to instantiate an empty AGPipeline.
 *
 * @param baseURL the URL of the server.
 *
 * @return the AGPipeline object.
 */
-(id) initWithBaseURL:(NSURL*) baseURL;

/**
 * An initializer method to instantiate an empty AGPipeline.
 *
 * @return the AGPipeline object.
 */
-(id) init;

/**
 * A factory method to instantiate an empty AGPipeline.
 *
 * @return the AGPipeline object.
 */
+(id) pipeline;

/**
 * A factory method to instantiate an empty AGPipeline.
 *
 * @param baseURL the URL of the server.
 *
 * @return the AGPipeline object.
 */
+(id) pipelineWithBaseURL:(NSURL*) baseURL;

/**
 * Adds a new AGPipe object, based on the given configuration object.
 *
 * @param config A block object which passes in an implementation of the AGPipeConfig protocol that is used to configure the AGPipe object.
 *
 * @return the newly created AGPipe object.
 */
-(id<AGPipe>) pipe:(void (^)(id<AGPipeConfig> config)) config;

/**
 * Removes a pipe from the AGPipeline object.
 *
 * @param name the name of the actual pipe.
 *
 * @return the new created AGPipe object.
 */
-(id<AGPipe>) remove:(NSString*) name;

/**
 * Look up for a pipe object.
 *
 * @param name the name of the actual pipe.
 *
 * @return the new created AGPipe object.
 */
-(id<AGPipe>) pipeWithName:(NSString*) name;

@end