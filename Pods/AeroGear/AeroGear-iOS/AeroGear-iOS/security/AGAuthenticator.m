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

#import "AGAuthenticator.h"
#import "AGRestAuthentication.h"
#import "AGAuthConfiguration.h"

@implementation AGAuthenticator {
    NSMutableDictionary* _modules;
}

- (id)init {
    self = [super init];
    if (self) {
        _modules = [NSMutableDictionary dictionary];
    }
    return self;
}

+(id) authenticator {
    return [[self alloc] init];
}

-(id<AGAuthenticationModule>) auth:(void (^)(id<AGAuthConfig> config)) config {
    AGAuthConfiguration* pipeConfig = [[AGAuthConfiguration alloc] init];
    
    if (config) {
        config(pipeConfig);
    }

    // TODO check ALL supported types...
    if (! [pipeConfig.type isEqualToString:@"AG_SECURITY"]) {
        return nil;
    }
    
    id<AGAuthenticationModule> module = [AGRestAuthentication moduleWithConfig:pipeConfig];
    [_modules setValue:module forKey:[pipeConfig name]];
    return module;
}

-(id<AGAuthenticationModule>)remove:(NSString*) moduleName {
    id<AGAuthenticationModule> module = [self authModuleWithName:moduleName];
    [_modules removeObjectForKey:moduleName];
    return module;
}

-(id<AGAuthenticationModule>)authModuleWithName:(NSString*) moduleName {
    return [_modules valueForKey:moduleName];
}

-(NSString *) description {
    return [NSString stringWithFormat: @"%@ %@", self.class, _modules];
}

@end