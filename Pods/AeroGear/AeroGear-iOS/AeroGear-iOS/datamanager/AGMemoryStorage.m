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

#import "AGMemoryStorage.h"

@implementation AGMemoryStorage

@synthesize type = _type;

// ==============================================
// ======== 'factory' and 'init' section ========
// ==============================================

+(id) storeWithConfig:(id<AGStoreConfig>) storeConfig {
    return [[self alloc] initWithConfig:storeConfig];
}

-(id) initWithConfig:(id<AGStoreConfig>) storeConfig {
    self = [super init];
    if (self) {
        // base inits:
        _type = @"MEMORY";
        _array = [NSMutableArray array];

        AGStoreConfiguration *config = (AGStoreConfiguration*) storeConfig;
        _recordId = config.recordId;
    }
    
    return self;
}

// =====================================================
// ======== public API (AGStore) ========
// =====================================================

-(NSArray*) readAll {
    // TODO: delegate to filter???
    return _array;
}

-(id) read:(id)recordId {
    id retVal;
    
    for (id record in _array) {
        // check the 'id':
        if ([[record objectForKey:_recordId] isEqual:recordId]) {
            // replace/update it:
            retVal = record;
            break;
        }
    }
    
    return retVal;
}

-(NSArray*) filter:(NSPredicate*)predicate {
    return [_array filteredArrayUsingPredicate:predicate];
}

-(BOOL) save:(id)data error:(NSError**)error {
    // a 'collection' of objects:
    if ([data isKindOfClass:[NSArray class]]) {

        // fail fast if the array contains non-dictionary objects
        for (id record in data) {
            if (![record isKindOfClass:[NSDictionary class]]) {
                
                if (error) {
                    *error = [self constructError:@"save" msg:@"array contains non-dictionary objects!"];
                    return false;
                }
            }
        }

        for (id record in data) {
            [self saveOne:record];
        }
       
    } else if([data isKindOfClass:[NSDictionary class]]) {
        // single obj:
        [self saveOne:data];

    } else { // not a dictionary, fail back
        if (error) {
            *error = [self constructError:@"save" msg:@"dictionary objects are supported only"];
            return NO;
        }
    }

    return YES;
}

//private save for one item:
-(void) saveOne:(NSDictionary*)data {
    // does the record already exist ?
    BOOL _objFound = NO;
    
    for (id record in _array) {
        // check the 'id':
        if ([[record objectForKey:_recordId] isEqual:[data objectForKey:_recordId]]) {
            // replace/update it:
            NSUInteger index = [_array indexOfObject:record];
            [_array removeObjectAtIndex:index];
            [_array addObject:data];
            //
            _objFound = YES;
            break;
        }
    }

    if (!_objFound) {
        // if the object hasnt' set a recordId property
        if ([data objectForKey:_recordId] == nil) {
            //generate a UIID to be used as this object recordId
            CFUUIDRef uuid = CFUUIDCreate(NULL);
            NSString *uuidStr = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, uuid);
            CFRelease(uuid);
            
            [data setValue:uuidStr forKey:_recordId];
        }
        
        // add it to our list
        [_array addObject:data];
    }
}

-(BOOL) reset:(NSError**)error {
    [_array removeAllObjects];
    
    return YES;
}

-(BOOL) remove:(id)record error:(NSError**)error {
    // check if null is provided and throw error
    if (record == nil || [record isKindOfClass:[NSNull class]]) {
        
        if (error) {
            *error = [self constructError:@"remove" msg:@"object was nil"];
            // do nothing
            return FALSE;
        }
    }
    
    id objectKey = [record objectForKey:_recordId];
    // we need to check if the map representation contains the "recordID" and its value is actually set:
    if (objectKey == nil || [objectKey isKindOfClass:[NSNull class]]) {
        
        if (error) {
            *error = [self constructError:@"remove" msg:@"recordId not set"];
            // do nothing
            return FALSE;
        }
    }

    id objectToDelete;
    
    for (id item in _array) {
        // check the 'id':
        if ([[item objectForKey:_recordId] isEqual:objectKey]) {
            // replace/update it:
            objectToDelete = item;
            NSUInteger index = [_array indexOfObject:item];
            [_array removeObjectAtIndex:index];
            break;
        }
    }
        
    return YES;
}

-(NSString *) description {
    return [NSString stringWithFormat: @"%@ [type=%@]", self.class, _type];
}

// =====================================================
// =========== private utility methods  ================
// =====================================================

-(NSError *) constructError:(NSString*) domain
                       msg:(NSString*) msg {
    
    NSError* error = [NSError errorWithDomain:[NSString stringWithFormat:@"org.aerogear.stores.%@", domain]
                                         code:0
                                     userInfo:[NSDictionary dictionaryWithObjectsAndKeys:msg,
                                               NSLocalizedDescriptionKey, nil]];
    
    return error;
}

@end
