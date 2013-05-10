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

#import "AGPropertyListStorage.h"

@implementation AGPropertyListStorage {
    NSString* _file;
}

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
        _type = @"PLIST";
        
        AGStoreConfiguration* config = (AGStoreConfiguration*) storeConfig;
        _recordId = config.recordId;
        
        // extract file path
        _file = [self storeFilePathWithName:config.name];
        
        // if file exists initialize store
        if ([[NSFileManager defaultManager] fileExistsAtPath:_file]) {
            _array = [[NSMutableArray alloc] initWithContentsOfFile:_file];
        } else { // create an empty store
            _array = [[NSMutableArray alloc] init];
        }
    }
    
    return self;
}

// =====================================================
// ======== public API (AGStore) ========
// =====================================================

-(BOOL) save:(id)data error:(NSError**)error {
    
    BOOL success = [super save:data error:error];
    
    if (!success)
        return FALSE;

    if (![_array writeToFile:_file atomically:YES]) {
        if (error) {
            *error = [self constructError:@"save" msg:@"error on save"];
            return FALSE;
        }
    }
    
    return YES;
}

-(BOOL) reset:(NSError**)error {
    BOOL success = [super reset:error];
    
    if (!success)
        return FALSE;
    
    if (![_array writeToFile:_file atomically:YES]) {
        if (error) {
            *error = [self constructError:@"reset" msg:@"error on reset"];
            return FALSE;
        }
    }
    
    return YES;
}

-(BOOL) remove:(id)record error:(NSError**)error {
    
    BOOL success = [super remove:record error:error];
    
    if (!success)
        return FALSE;
    
    if (![_array writeToFile:_file atomically:YES]) {
        if (error) {
            *error = [self constructError:@"remove" msg:@"error on remove"];
            return FALSE;
        }
    }
    
    return YES;
}

// =====================================================
// =========== private utility methods  ================
// =====================================================

-(NSString*) storeFilePathWithName:(NSString*) name {
    // calculate path
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsDirectory = [paths objectAtIndex:0];
    
    // create the Documents directory if it doesn't exist
    BOOL isDir;
    if (![[NSFileManager defaultManager] fileExistsAtPath:documentsDirectory isDirectory:&isDir]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:documentsDirectory
                                  withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    // the filename is based on this store name
    return [documentsDirectory stringByAppendingPathComponent:name];
}

@end
