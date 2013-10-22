//
//  HNManager.m
//  libHN-Demo
//
//  Created by Ben Gordon on 10/6/13.
//  Copyright (c) 2013 subvertapps. All rights reserved.
//

#import "HNManager.h"

@implementation HNManager

// Build the static manager object
static HNManager * _sharedManager = nil;


#pragma mark - Set Up HNManager's Singleton
+ (HNManager *)sharedManager {
	@synchronized([HNManager class]) {
		if (!_sharedManager)
            _sharedManager  = [[HNManager alloc] init];
		return _sharedManager;
	}
	return nil;
}

+ (id)alloc {
	@synchronized([HNManager class]) {
		NSAssert(_sharedManager == nil, @"Attempted to allocate a second instance of a singleton.");
		_sharedManager = [super alloc];
		return _sharedManager;
	}
	return nil;
}

- (instancetype)init {
	if (self = [super init]) {
        // Set up Webservice
        self.Service = [[HNWebService alloc] init];
	}
	return self;
}


#pragma mark - WebService Methods
- (void)loginWithUsername:(NSString *)user password:(NSString *)pass completion:(SuccessfulLoginBlock)completion {
    [self.Service loginWithUsername:user pass:pass completion:^(HNUser *user, NSHTTPCookie *cookie) {
        if (user) {
            // Set Session
            self.SessionUser = user;
            self.SessionCookie = cookie;
            
            // Pass user on through
            completion(user);
        }
        else {
            completion(nil);
        }
    }];
}

- (void)logout {
    // Delete cookie from Storage
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:self.SessionCookie];
    
    // Delete objects in memory
    self.SessionCookie = nil;
    self.SessionUser = nil;
    
}

- (void)loadPostsWithFilter:(PostFilterType)filter completion:(GetPostsCompletion)completion {
    [self.Service loadPostsWithFilter:filter completion:completion];
}

- (void)loadPostsWithFNID:(NSString *)fnid completion:(GetPostsCompletion)completion {
    [self.Service loadPostsWithFNID:fnid completion:completion];
}

- (void)loadCommentsFromPost:(HNPost *)post completion:(GetCommentsCompletion)completion {
    [self.Service loadCommentsFromPost:post completion:completion];
}

- (void)submitPostWithTitle:(NSString *)title link:(NSString *)link text:(NSString *)text completion:(BooleanSuccessBlock)completion {
    if ((!link && !text) || !title) {
        // No link and text, or no title - can't submit
        completion(NO);
        return;
    }
    
    // Make the Webservice Call
    [self.Service submitPostWithTitle:title link:link text:text completion:completion];
}

- (void)replyToPostOrComment:(id)hnObject withText:(NSString *)text completion:(BooleanSuccessBlock)completion {
    if (!hnObject || !text) {
        // You need a Post/Comment and text to make a reply!
        completion(NO);
        return;
    }
    
    // Make the Webservice call
    [self.Service replyToHNObject:hnObject withText:text completion:completion];
}

- (void)voteOnPostOrComment:(id)hnObject direction:(VoteDirection)direction completion:(BooleanSuccessBlock)completion {
    if (!hnObject || !direction) {
        // Must be a Post/Comment and direction to vote!
        completion(NO);
        return;
    }
    
    // Make the Webservice Call
    [self.Service voteOnHNObject:hnObject direction:direction completion:completion];
}

- (void)fetchSubmissionsForUser:(NSString *)user completion:(GetPostsCompletion)completion {
    if (!user) {
        // Need a username to get their submissions!
        completion(nil);
        return;
    }
    
    // Make the webservice call
    [self.Service fetchSubmissionsForUser:user completion:completion];
}


#pragma mark - Set Cookie & User
- (void)validateAndSetCookieWithCompletion:(LoginCompletion)completion {
    NSHTTPCookie *cookie = [HNManager getHNCookie];
    if (cookie) {
        [self.Service validateAndSetSessionWithCookie:cookie completion:completion];
    }
}

+ (NSHTTPCookie *)getHNCookie {
    NSArray *cookieArray = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:@"https://news.ycombinator.com/"]];
    if (cookieArray.count > 0) {
        NSHTTPCookie *cookie = cookieArray[0];
        if ([cookie.name isEqualToString:@"user"]) {
            return cookie;
        }
    }
    
    return nil;
}

- (BOOL)isUserLoggedIn {
    return (self.SessionCookie != nil && self.SessionUser != nil);
}



@end
