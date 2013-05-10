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

#import "AGPipeline.h"
#import "AGPipeConfiguration.h"
#import "AGRESTPipe.h"

// category
@interface AGPipeline ()
// concurrency...
@property (atomic, copy) NSMutableDictionary* pipes;
@end

@implementation AGPipeline {
    // ivars...
    NSURL* _baseURL;
}
@synthesize pipes = _pipes;


- (id)init {
    self = [super init];
    if (self) {
        _pipes = [NSMutableDictionary dictionary];
    }
    return self;
}

- (id)initWithBaseURL:(NSURL*) baseURL {
    self = [self init];
    if (self) {
        
        // stash the baseURL, used for the 'add' functions that have no (base)URL argument
        _baseURL = baseURL;
    }
    return self;
}

+(id)pipeline {
    return [[self alloc] init];
}

+(id)pipelineWithBaseURL:(NSURL*) baseURL; {
    return [[self alloc] initWithBaseURL:baseURL];
}

-(id<AGPipe>) pipe:(void (^)(id<AGPipeConfig> config)) config {
    AGPipeConfiguration* pipeConfig = [[AGPipeConfiguration alloc] init];

    // applying the defaults:
    [pipeConfig setBaseURL:_baseURL];

    if (config) {
        config(pipeConfig);
    }
    
    // TODO check ALL supported types...
    if (! [pipeConfig.type isEqualToString:@"REST"]) {
        return nil;
    }

    id<AGPipe> pipe = [AGRESTPipe pipeWithConfig:pipeConfig];
    [_pipes setValue:pipe forKey:[pipeConfig name]];
    
    return pipe;
}

-(id<AGPipe>) remove:(NSString*) name {
    id<AGPipe> pipe = [self pipeWithName:name];
    [_pipes removeObjectForKey:name];
    
    return pipe;
}

-(id<AGPipe>) pipeWithName:(NSString*) name {
    return [_pipes valueForKey:name];
}

-(NSString *) description {
    return [NSString stringWithFormat: @"%@ %@", self.class, _pipes];
}

@end
