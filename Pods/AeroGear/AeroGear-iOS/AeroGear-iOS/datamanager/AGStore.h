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

/**
 * AGStore represents an abstraction layer for a storage system.
 */
@protocol AGStore <NSObject>

/**
 * Returns the type of the underlying 'store implementation'
 */
@property (nonatomic, readonly) NSString* type;

/**
 * Reads all the data from the underlying storage system.
 *
 * @return A collection (NSArray), containing all stored objects.
 */
-(NSArray*) readAll;

/**
 * Reads a specific object/record from the underlying storage system.
 *
 * @param recordId id from the desired object.
 *
 * @return The object (or nil) read from the underlying storage.
 */
-(id) read:(id)recordId;

/**
 * Reads all, based on a filter, from the underlying storage system.
 *
 * @param predicate The NSPredicate to apply to the data from the underlying storage system.
 *
 * @return A collection (NSArray), containing all stored objects, matching the given predicate.
 * This method only returns a copy of the data and leaves the underlying storage system intact.
 */
-(NSArray*) filter:(NSPredicate*)predicate;

/**
 * Saves the given object in the underlying storage system.
 *
 * @param data An object or a collection (e.g. NSArray) which is being persisted.
 * @param error An error object containing details of why the save failed. 
 *
 * @return YES if the operation succeeds, otherwise NO.
 */
-(BOOL) save:(id)data error:(NSError**)error;

/**
 * Resets the entire storage system.
 *
 * @param error An error object containing details of why the reset failed.
 *
 * @return YES if the operation succeeds, otherwise NO.
 */
-(BOOL) reset:(NSError**)error;

/**
 * Removes a specific object/record from the underlying storage system.
 *
 * @param record the desired object
 * @param error An error object containing details of why the remove failed.
 *
 * @return YES if the operation succeeds, otherwise NO.
 */
-(BOOL) remove:(id)record error:(NSError**)error;

@end
