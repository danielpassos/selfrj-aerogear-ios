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

#import "AGBaseAdapter.h"

@implementation AGBaseAdapter


// abstract:
- (id)init {
    if ([self class] == [AGBaseAdapter class]) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                            reason:@"Error, attempting to instantiate AGBaseAdapter directly."
                            userInfo:nil];
    }
    
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    return self;
}

+(BOOL)accepts:(NSString *)type {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                        reason:[NSString stringWithFormat:@"You must override %@ in a subclass",
                                NSStringFromSelector(_cmd)]
                        userInfo:nil];
}

@end
