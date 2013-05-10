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
#import "AGStore.h"
#import "AGStoreConfiguration.h"

/**
 An internal AGStore implementation that uses "in-memory" storage.
 
 *IMPORTANT:* Users are not required to instantiate this class directly, instead an instance of this class is returned automatically when an DataStore with default configuration is constructed or with the _type_ config option set to _"MEMORY"_. See AGDataManager and AGStore class documentation for more information.

 */
@interface AGMemoryStorage : NSObject <AGStore> {

@protected
    NSMutableArray* _array;
    NSString* _recordId;
}

+(id) storeWithConfig:(id<AGStoreConfig>) storeConfig;
-(id) initWithConfig:(id<AGStoreConfig>) storeConfig;

-(NSError *) constructError:(NSString*) domain
                        msg:(NSString*) msg;

@end
