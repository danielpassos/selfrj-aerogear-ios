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
AGAuthenticationModule represents an authentication module and provides the authentication and enrollment API. The default implementation uses REST as the auth transport. Similar to the [Pipe](AGPipe), technical details of the underlying system are not exposed.

## Register a user

The ```enroll``` function of the _AGAuthenticationModule_ protocol is used to register new users with the backend:

    // assemble the dictionary that has all the data for THIS particular user:
    NSMutableDictionary* userData = [NSMutableDictionary dictionary];
    [userData setValue:@"john" forKey:@"username"];
    [userData setValue:@"123" forKey:@"password"];
    [userData setValue:@"me@you.com" forKey:@"email"];
    [userData setValue:@"21sda812sad24" forKey:@"betaAccountToken"];

    // register a new user
    [myMod enroll:userData success:^(id data) {
        // after a successful _registration_, we can work
        // with the returned data...
        NSLog(@"We got: %@", data);
    } failure:^(NSError *error) {
        // when an error occurs... at least log it to the console..
        NSLog(@"SAVE: An error occured! \n%@", error);
    }];

The ```enroll``` function submits a generic map object with contains all the information about the new user, that the server endpoint requires. The default (REST) auth module issues for the above a request against _https://todoauth-aerogear.rhcloud.com/todo-server/auth/enroll_. Besides the NSDictionary, the function accepts two simple blocks that are invoked on success or in case of an failure.

## Login 

Once you have a _valid_ user you can use that information to issue a login against the server, to start accessing protected endpoints:

    // issuing a login
    [myMod login:@"john" password:@"123" success:^(id object) {
        // after a successful _login_, we can work
        // with the returned data...
    } failure:^(NSError *error) {
        // when an error occurs... at least log it to the console..
        NSLog(@"SAVE: An error occured! \n%@", error);
    }];

The default (REST) auth module issues for the above a request against _https://todoauth-aerogear.rhcloud.com/todo-server/auth/login_. Besides the _username_ and the _password_, the function accepts two simple blocks that are invoked on success or in case of an failure.

## Pass the auth module to a pipe

After running a successful login, you can start using the _AGAuthenticationModule_ object on a _AGPipe_ object to access protected endpoints:

    ...
    id<AGPipe> tasks = [pipeline pipe:^(id<AGPipeConfig> config) {
        [config setName:@"tasks"];
        [config setBaseURL:serverURL];
        [config setAuthModule:myMod];
    }];

    [tasks read:^(id responseObject) {
        // LOG the JSON response, returned from the server:
        NSLog(@"READ RESPONSE\n%@", [responseObject description]);
    } failure:^(NSError *error) {
        // when an error occurs... at least log it to the console..
        NSLog(@"Read: An error occured! \n%@", error);
    }];

When creating a [Pipe](AGPipe) you need to use the _authModule_ argument in order to pass in an _AGAuthenticationModule_ object.

## Logout

The logout from the server can be archived by using the ```logout``` function:

    // logout:
    [myMod logout:^{
        // after a successful _logout_, when can notify the application
    } failure:^(NSError *error) {
        // when an error occurs... at least log it to the console..
        NSLog(@"SAVE: An error occured! \n%@", error);
    }];

The default (REST) auth module issues for the above a request against _https://todoauth-aerogear.rhcloud.com/todo-server/auth/logout_. The function accepts two simple blocks that are invoked on success or in case of an failure.

## Time out and Cancel pending operations

As with the case of Pipe, configured timeout interval (in the config object) and cancel operation in _AGAuthenticationModule_ is supported too.  
 */
@protocol AGAuthenticationModule <NSObject>

/**
 * Returns the type of the underlying 'auth module implementation'
 */
@property (nonatomic, readonly) NSString* type;

/**
 * Returns the baseURL string of the underlying 'auth module implementation'
 */
@property (nonatomic, readonly) NSString* baseURL;

/**
 * Returns the 'login endpoint' of the underlying 'auth module implementation'
 */
@property (nonatomic, readonly) NSString* loginEndpoint;

/**
 * Returns the 'logout endpoint' of the underlying 'auth module implementation'
 */
@property (nonatomic, readonly) NSString* logoutEndpoint;

/**
 * Returns the 'enroll endpoint' of the underlying 'auth module implementation'
 */
@property (nonatomic, readonly) NSString* enrollEndpoint;


/**
 * Performs a signup of a new user. The request accepts a NSDictionary which will be translated to JSON 
 * and send to the endpoint.
 *
 * @param userData A map (NSDictionary) containing all the information requested by the
 * 'registration' service.
 *
 * @param success A block object to be executed when the operation finishes successfully.
 * This block has no return value and takes one argument: A collection (NSDictionary), containing the response
 * from the 'signup' service.
 *
 * @param failure A block object to be executed when the operation finishes unsuccessfully.
 * This block has no return value and takes one argument: The `NSError` object describing
 * the error that occurred.
 */
-(void) enroll:(id) userData
     success:(void (^)(id object))success
     failure:(void (^)(NSError *error))failure;

/**
 * Performs the login for the given user. Since the data will be sent in plaintext, it is IMPORTANT,
 * to run the signin via TLS/HTTPS.
 *
 * @param username username
 *
 * @param password password
 *
 * @param success A block object to be executed when the operation finishes successfully.
 * This block has no return value and takes one argument: A collection (NSDictionary), containing the response
 * from the 'login' service.
 *
 * @param failure A block object to be executed when the operation finishes unsuccessfully.
 * This block has no return value and takes one argument: The `NSError` object describing
 * the error that occurred.
 */
-(void) login:(NSString*) username
    password:(NSString*) password
     success:(void (^)(id object))success
     failure:(void (^)(NSError *error))failure;

/**
 * Performs the logout of the current user.
 *
 * @param success A block object to be executed when the operation finishes successfully.
 * This block has no return value and takes no argument.
 *
 * @param failure A block object to be executed when the operation finishes unsuccessfully.
 * This block has no return value and takes one argument: The `NSError` object describing
 * the error that occurred.
 */
-(void) logout:(void (^)())success
     failure:(void (^)(NSError *error))failure;

/**
 * Cancel all running pipe operations. Any registered callbacks on the auth module are NOT executed.
 * It is your responsibility to provide any neccessary cleanups after calling this method.
 *
 */
-(void) cancel;

@end
