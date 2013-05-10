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

#import <objc/runtime.h>
#import "AGNSMutableArray+Paging.h"

static char const * const AGPipeKey = "AGPipeKey";
static char const * const AGParamProviderKey = "AGParamProviderKey";
@implementation NSMutableArray (AGPaging)


#pragma mark paging category 
-(void) next:(void (^)(id responseObject))success
     failure:(void (^)(NSError *error))failure {
    
    
    [self.pipe readWithParams:[self.parameterProvider valueForKey:@"AG-next-key"] success:^(id responseObject) {
        if (success) {
            success(responseObject);
        }
    } failure:^(NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

-(void) previous:(void (^)(id responseObject))success
     failure:(void (^)(NSError *error))failure {
    
    [self.pipe readWithParams:[self.parameterProvider valueForKey:@"AG-prev-key"] success:^(id responseObject) {
        if (success) {
            success(responseObject);
        }
    } failure:^(NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

#pragma mark accessor AssociatedObjects
-(void) setPipe:(id<AGPipe>)pipe {
    objc_setAssociatedObject(self, AGPipeKey, pipe, OBJC_ASSOCIATION_ASSIGN);
    
}

-(id<AGPipe>) pipe {
    return objc_getAssociatedObject(self, AGPipeKey);
}
-(void) setParameterProvider:(NSDictionary *)parameterProvider {
    objc_setAssociatedObject(self, AGParamProviderKey, parameterProvider, OBJC_ASSOCIATION_ASSIGN);
    
}

-(NSDictionary *) parameterProvider {
    return objc_getAssociatedObject(self, AGParamProviderKey);
}
@end
