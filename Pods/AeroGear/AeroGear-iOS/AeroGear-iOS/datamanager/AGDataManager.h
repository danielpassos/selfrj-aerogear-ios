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
#import "AGStoreConfig.h"

/**
  AGDataManager manages different AGStore implementations. It is basically a
  factory that hides the concrete instantiations of a specific AGStore implementation.
  The class offers simple APIs to add, remove or get access to a 'data store'.
 
  NOTE: Right now, there is NO automatic data sync. This is up to the user.

## Create a DataManager with a Store object:

Below is simple example that creates a DataManager initialized to use the default _in-memory_ store.

    // create the datamanager
    AGDataManager* dm = [AGDataManager manager];
    // add a new (default) store object:
    id<AGStore> myStore = [dm store:^(id<AGStoreConfig> config) {
        [config setName:@"tasks"];
        [config setType:@"MEMORY"];  // can be omitted, the default is an "in-memory" store
    }];

Similar to the [Pipe](AGPipe) API, technical details of the underlying system are not exposed.

## Save data to the Store

Below is an example that stores the received objects, read from the [AGPipe read:failure:] method.

    ....
    id<AGPipe> talkPipe = [todo get:@"tasks"];
    ...

    [talkPipe read:^(id responseObject) {
        // the response object represents an NSArray,
        // containing multile 'Tasks' (as NSDictionary objects)

        // Save the response object to the store
        NSError *error;
        
        if (![myStore save:responseObject error:&error])
            NSLog(@"Save: An error occured during save! \n%@", error);    

    } failure:^(NSError *error) {
        // when an error occurs... at least log it to the console..
        NSLog(@"Read: An error occured! \n%@", error);
    }];

When loading all tasks from the server, the AGStore object is used inside of the _read_ block from the AGPipe object. The returned collection of tasks is stored inside our in-memory store, from where the data can be accessed.

## Read an object from the Store

The ```read``` function accepts the _recordID_ of the object you want to retrieve. If the object does not exist in the store, _nil_ is returned.

    // read the task with the '0' ID:
    id taskObject =  [myStore read:@"0"];

If you want to read _all_ the objects contained in the store, simply call the ```readAll``` function

    // read all objects from the store
    NSArray *objects = [myStore readAll];

## Remove one object from the Store

The ```remove``` function allows you to delete a single entry in the collection, if present:

    // remove the task with the '0' ID:
    NSError *error;

    if (![myStore remove:@"0" error:error])
        NSLog(@"Save: An error occured during remove! \n%@", error);    

The remove method accepts the _recordID_ of the object you want to remove. If the object does not exist in the store, FALSE is returned.

## Filter the entire Store

Filtering of the data available in the AGStore is also supported, by using the familiar NSPredicate class available in iOS. In the following example, after storing a pair of dictionaries representing user information details in the store (which can be easily come from a response from a server), we simple call the _filter_ method to filter out the desired information:
     
     NSMutableDictionary *user1 = [@{@"id" : @"1",
                                    @"name" : @"Robert",
                                    @"city" : @"Boston",
                                    @"department" : @{@"name" : @"Software", @"address" : @"Cornwell"},
                                    @"experience" : @[@{@"language" : @"Java", @"level" : @"advanced"},
                                                      @{@"language" : @"C", @"level" : @"advanced"}]
                                  } mutableCopy];
    
    NSMutableDictionary *user2 = [@{@"id" : @"2",
                                    @"name" : @"David",
                                    @"city" : @"Boston",
                                    @"department" : @{@"name" : @"Software", @"address" : @"Cornwell"},
                                    @"experience" : @[@{@"language" : @"Java", @"level" : @"intermediate"},
                                                      @{@"language" : @"Python", @"level" : @"intermediate"}]
                                  } mutableCopy];

    NSMutableDictionary *user3 = [@{@"id" : @"3",
                                    @"name" : @"Peter",
                                    @"city" : @"Boston",
                                    @"department" : @{@"name" : @"Software", @"address" : @"Branton"},
                                    @"experience" : @[@{@"language" : @"Java", @"level" : @"advanced"},
                                                      @{@"language" : @"C", @"level" : @"intermediate"}]
                                  } mutableCopy];

    // save objects
    BOOL success = [_memStore save:users error:nil];

    if (success) { // if save succeeded, query the data
        NSPredicate *predicate = [NSPredicate
                                  predicateWithFormat:@"city = 'Boston' AND department.name = 'Software' \
                                  AND SUBQUERY(experience, $x, $x.language = 'Java' AND $x.level = 'advanced').@count > 0" ];

        NSArray *results = [_memStore filter:predicate];

        // The array now contains the dictionaries _user1_ and _user_3, since they both satisfy the query predicate.
        // do something with the 'results'
        // ...
    }

Using NSPredicate to filter desired data, is a powerful mechanism offered in iOS and we strongly suggest to familiarize yourself with it, if not already. Take a look at Apple's own [documentation](http://tinyurl.com/chmgwv5) for more information.

## Reset the entire Store

The reset function allows you the erase all data available in the used AGStore object:

    // clears the entire store
    NSError *error;

    if (![myStore reset:&error])
        NSLog(@"Reset: An error occured during reset! \n%@", error);    

 */
@interface AGDataManager : NSObject

/**
 * A factory method to instantiate the AGDataManager object.
 *
 * @return the AGDataManager object
 */
+(id) manager;

/**
 * Adds a new AGStore object, based on the given configuration object.
 *
 * @param config A block object which passes in an implementation of the AGStoreConfig protocol.
 * the object is used to configure the AGStore object.
 *
 * @return the newly created AGStore object.
 */
-(id<AGStore>) store:(void (^)(id<AGStoreConfig> config)) config;

/**
 * Removes a AGStore implementation from the AGDataManager. The store to be removed
 * is determined by the storeName argument.
 *
 * @param storeName The name of the actual data store object.
 */
-(id<AGStore>)remove:(NSString*) storeName;

/**
 * Loads a given AGStore implementation, based on the given storeName argument.
 *
 * @param storeName The name of the actual data store object.
 */
-(id<AGStore>)storeWithName:(NSString*) storeName;

@end
