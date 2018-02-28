//
//  AVUserTest.m
//  paas
//
//  Created by Travis on 14-3-6.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import "AVTestBase.h"
#import "AVPaasClient.h"
#import "AVCustomUser.h"
#import "AVUser_Internal.h"

static dispatch_time_t dTimeout(NSTimeInterval interval) {
    return dispatch_time(DISPATCH_TIME_NOW, interval * NSEC_PER_SEC);
}

// MARK: - XXUser

@interface XXUser : AVUser<AVSubclassing>

@property (nonatomic, assign) int age;

@end

@implementation XXUser

@dynamic age;

@end

// MARK: - TestUser

@interface TestUser : AVUser

@property (nonatomic, strong) NSString *testAttr;

@end

@implementation TestUser

- (void)setTestAttr:(NSString *)testAttr {
    [self setObject:testAttr forKey:@"_testAttr"];
}

- (NSString *)testAttr {
    return [self objectForKey:@"_testAttr"];
}

@end

// MARK: - AVUserTest

@interface AVUserTest : AVTestBase

@end

@implementation AVUserTest

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testCurrentUser {
    NSError *error = nil;
    {
        [AVUser logOut];
        AVUser *user = [AVUser currentUser];
        XCTAssertNil(user);
    }
    {
        AVUser *user = [AVUser user];
        user.username = @"testCurrentUser";
        user.password = @"111111";
        [user signUp:&error];
        user = [AVUser currentUser];
        XCTAssertNotNil(user);
        [self addDeleteObject:user];
    }
}

-(void)testSignUp{
    [self deleteUserWithUsername:@"testSignUp" password:@"111111"];
    
    AVUser *user=[AVUser user];
    user.email=[NSString stringWithFormat:@"%ld@qq.com", (long)arc4random()];
    user.username=@"testSignUp";
    user.password=@"111111";
    [user setObject:@"bio" forKey:@"helloworld"];
    NSError *err=nil;
    [user signUp:&err];
    [self addDeleteObject:user];
    //XCTestAssertNil(err,@"%@",err);
    XCTAssertNil(err,@"%@",err);
}

-(void)testEmailVerify{
    [self deleteUserWithUsername:NSStringFromSelector(_cmd) password:@"111111"];
    
    AVUser *user=[AVUser user];
    user.email=@"651142978@qq.com";
    user.username=NSStringFromSelector(_cmd);
    user.password=@"111111";
    NSError *err=nil;
    [user signUp:&err];
    XCTAssertNil(err);
    [self addDeleteObject:user];
    
    // 需要启用邮箱验证
    [AVUser requestEmailVerify:@"651142978@qq.com" withBlock:^(BOOL succeeded, NSError *err) {
        if (err && err.code!=kAVErrorUserWithEmailNotFound && err.code != kAVErrorInternalServer) {
            NSLog(@"%@",err);
            [self notify:XCTAsyncTestCaseStatusFailed];
        } else {
            [self notify:XCTAsyncTestCaseStatusSucceeded];
        }
        
    }];
    WAIT_10;
}

//FIXME:Test Fails
- (void)testUserWithFile {
    [self deleteUserWithUsername:NSStringFromSelector(_cmd) password:@"123456"];
    
    AVUser *user=[AVUser user];
    user.email=@"test1111@qq.com";
    user.username=NSStringFromSelector(_cmd);
    user.password=@"123456";
    NSError *err=nil;
    [user signUp:&err];
    [self addDeleteObject:user];
    XCTAssertNil(err, @"%@", err);
    
    AVFile *file = [AVFile fileWithData:[[NSString stringWithFormat:@"%@", NSStringFromSelector(_cmd)] dataUsingEncoding:NSUTF8StringEncoding]];
    [[AVUser currentUser] setObject:file forKey:NSStringFromSelector(_cmd)];
    err = nil;
    [[AVUser currentUser] save:&err];
    [self addDeleteFile:file];
    XCTAssertNil(err, @"%@", err);
    err = nil;
    user = [AVUser logInWithUsername:NSStringFromSelector(_cmd) password:@"123456" error:&err];
    [[AVUser currentUser] setObject:file forKey:NSStringFromSelector(_cmd)];
    err = nil;
    [[AVUser currentUser] save:&err];
    XCTAssertNil(err, @"%@", err);
    NSString *filePath=[[NSBundle bundleForClass:[self class]] pathForResource:@"alpacino" ofType:@"jpg"];
    AVFile *fileLarge = [AVFile fileWithName:@"alpacino.jpg" contentsAtPath:filePath];
    [fileLarge save:&err];
    XCTAssertNil(err, @"%@", err);
    [self addDeleteFile:fileLarge];
    [[AVUser currentUser] setObject:file forKey:NSStringFromSelector(_cmd)];
    [[AVUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        XCTAssertNil(error, @"%@", error);
        NOTIFY;
    }];
    WAIT;
}

- (void)testSignUpUserWithFile {
    
    AVFile *file = [AVFile fileWithData:[[NSString stringWithFormat:@"%@", NSStringFromSelector(_cmd)] dataUsingEncoding:NSUTF8StringEncoding]];
    AVUser *user=[AVUser user];
    user.email=@"test@qq.com";
    user.username=NSStringFromSelector(_cmd);
    user.password=@"123456";
    [user setObject:file forKey:NSStringFromSelector(_cmd)];
    NSError *err=nil;
    [user signUp:&err];
    [self addDeleteFile:file];
    [self addDeleteObject:user];
    XCTAssertNil(err, @"%@", err);
    //    [[AVUser currentUser] setObject:file forKey:NSStringFromSelector(_cmd)];
    //    NSError *err = nil;
    //    [[AVUser currentUser] save:&err];
    //    XCTAssertNil(err, @"%@", err);
}

- (void)testUpdatePassword {
//    NSError *err = nil;
//    AVUser *user=[AVUser user];
//    user.username=NSStringFromSelector(_cmd);
//    user.password=@"111111";
//    XCTAssertTrue([user signUp:&err], @"%@", err);
//    //    [AVUser logInWithUsername:@"username" password:@"password"];
//    err = nil;
//    [user updatePassword:@"111111" newPassword:@"123456" withTarget:self selector:@selector(passwordUpdated:error:)];
//    user.password=@"123456";
//    [self addDeleteObject:user];
//    WAIT;
}

- (void)passwordUpdated:(AVObject *)object error:(NSError *)error {
    XCTAssertNil(error, @"%@", error);
    NOTIFY;
}

- (void)testUpdatePassword2 {
    AVUser *user = [self registerOrLoginWithUsername:NSStringFromSelector(_cmd)];
    [user updatePassword:@"111111" newPassword:@"123456" block:^(id object, NSError *error) {
        XCTAssertNil(error, @"%@", error);
        XCTAssertEqual(object, user);
        XCTAssertEqual(object,[AVUser currentUser]);
        
        // check sessionToken
        user.username = @"afterUpdatePassword";
        NSError *theError;
        [user save:&theError];
        XCTAssertNil(theError);
        
        NOTIFY;
    }];
    WAIT;
    user.password=@"123456"; // to login and delete it
    [self addDeleteObject:user];
}

- (void)testSubClass {
//    NSError *error = nil;
    TestUser *user=[TestUser user];
    user.username=NSStringFromSelector(_cmd);
    user.password=@"111111";
    user.testAttr=@"test";
    //    XCTAssertTrue([user signUp:&error], @"%@", error);
    [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        XCTAssertTrue(succeeded, @"%@", error);
        NSLog(@"%@", user.testAttr);
        NOTIFY;
    }];
    [self addDeleteObject:user];
    WAIT;
}

- (void)testAnonymousUser {
    [AVAnonymousUtils logInWithBlock:^(AVUser *user, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(user);
        XCTAssertNotNil(user.username);
        NOTIFY;
    }];
    WAIT;
}

- (void)testUsernameWithChinese {
    AVUser *user=[AVUser user];
    user.email=@"abcgf@qq.com";
    user.username=@"测试账户";
    user.password=@"111111";
    [user setObject:@"你好" forKey:@"abc"];
    NSError *err=nil;
    [user signUp:&err];
    [self addDeleteObject:user];
    //XCTestAssertNil(err,@"%@",err);
    XCTAssertNil(err,@"%@",err);
    AVQuery * query = [AVUser query];
    AVObject *obj = [query getObjectWithId:user.objectId];
    NSLog(@"%@", [obj objectForKey:@"username"]);
    [query whereKey:@"objectId" equalTo:user.objectId];
    NSArray* users=[query findObjects];
    for (AVUser *usr in users) {
        NSLog(@"%@", usr.username);
    }
    
}

- (void)testFollowerQueryClassName {
    AVUser *user=[AVUser user];
    user.email=@"etrtdgf@qq.com";
    user.username=NSStringFromSelector(_cmd);
    user.password=@"111111";
    [user setObject:@"你好" forKey:@"abc"];
    NSError *err=nil;
    [user signUp:&err];
    [self addDeleteObject:user];
    AVQuery *query = [AVQuery orQueryWithSubqueries:@[[AVUser currentUser].followerQuery]];
    [query findObjects];
}

- (void)testBecomeWithSessionToken {
    AVUser *user = [self registerOrLoginWithUsername:@"testBecome"];
    
    AVUser *otherUser = [self registerOrLoginWithUsername:@"testBecome1"];
    
    NSString *sessionToken = user.sessionToken;
    XCTAssertNotNil(sessionToken);
    
    [AVUser becomeWithSessionTokenInBackground:sessionToken block:^(AVUser *newUser, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(newUser);
        XCTAssertEqualObjects(newUser.sessionToken, sessionToken);
        XCTAssertEqualObjects(newUser.createdAt, user.createdAt);
        XCTAssertEqualObjects(newUser.objectId, user.objectId);
        NOTIFY;
    }];
    WAIT;
    
    AVUser *currentUser = [AVUser currentUser];
    XCTAssertEqualObjects(user.objectId, currentUser.objectId);
    XCTAssertEqualObjects(user.createdAt, currentUser.createdAt);
    
    NSError *error;
    AVUser *loginUser = [AVUser becomeWithSessionToken:otherUser.sessionToken error:&error];
    XCTAssertEqualObjects(loginUser.objectId, otherUser.objectId);
    
    XCTAssertNil(error);
    //    [self addDeleteObject:user];
}

- (void)testSubclassAVUser {
    // 如果下面这个语句删掉，就会出现 https://github.com/leancloud/ios-sdk/issues/43 描述的问题。
    [AVCustomUser registerSubclass];
    
    AVCustomUser *user = [[AVCustomUser alloc] init];
    
    user.username = [@"foo" stringByAppendingFormat:@"%@", @(arc4random())];
    user.password = [@"bar" stringByAppendingFormat:@"%@", @(arc4random())];
    
    NSError *error = nil;
    [user signUp:&error];
    
    XCTAssert(!error, @"%@", error);
    
    AVQuery *query = [AVQuery queryWithClassName:@"_User"];
    
    [query whereKey:@"objectId" equalTo:user.objectId];
    NSArray *users = [query findObjects:&error];
    
    XCTAssert(!error, @"%@", error);
    
    id queriedUser = [users firstObject];
    
    XCTAssert(queriedUser != nil, @"%@", error);
    XCTAssert([queriedUser isKindOfClass:[AVCustomUser class]], @"AVQuery can not deserialize AVUser subclass");
}

-(void)testSubUser {
    [XXUser registerSubclass];
    NSError *err = nil;
    XXUser *user2=[XXUser logInWithUsername:@"travis" password:@"123456" error:&err];
    
    XCTAssertEqual([user2 class], [XXUser class], @"AVUser子类返回错误");
    XCTAssertEqual([[XXUser currentUser] class], [XXUser class], @"AVUser子类返回错误");
}

- (void)testSubclassUserIngoreCurrentClass {
    [AVCustomUser registerSubclass];
    
    AVCustomUser *user = [[AVCustomUser alloc] init];
    user.username = [@"sex" stringByAppendingFormat:@"%@", @(arc4random())];
    user.password = [@"sexual" stringByAppendingFormat:@"%@", @(arc4random())];
    NSError *error = nil;
    [user signUp:&error];
    assertNil(error);
    
    AVUser *loginUser = [XXUser logInWithUsername:user.username password:user.password error:&error];
    assertNil(error);
    assertEqual([loginUser class], [AVCustomUser class]);
}

- (void)testUserSave {
    //Relation
    NSError *err = nil;
    [AVUser logInWithUsername:@"travis" password:@"123456" error:&err];
    int racInt = arc4random_uniform(10);
    NSString *email = [NSString stringWithFormat:@"%@luohanchenyilong@163.com",@(racInt)];
    [AVUser currentUser].email = email;
    
    [[AVUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        XCTAssertNil(error);
        XCTAssertEqual( [AVUser currentUser].email, email);
        NOTIFY
    }];
    WAIT
    
    // relation测试
    AVQuery *query = [AVQuery queryWithClassName:@"AVRelationTest_Post"];
    [query getObjectInBackgroundWithId:@"568fd58ccbc2e8a30c525820" block:^(AVObject *object, NSError *error) {
        if (!error) {
            AVRelation *relation = [[AVUser currentUser] relationForKey:@"myLikes"];
            [relation addObject:object];
            [[AVUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                XCTAssertNil(error);
                NOTIFY
            }];
        }
    }];
    WAIT
    
    //Test for this forum ticket https://forum.leancloud.cn/t/avrelation/5616
    AVRelation *relation2 = [[AVUser currentUser] relationForKey:@"myLikes"];
    [[relation2 query] findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        BOOL isFinded = NO;
        for (AVObject *object in objects) {
            if ([object.objectId isEqualToString:@"568fd58ccbc2e8a30c525820"]) {
                isFinded = YES;
                break;
            }
        }
        XCTAssertEqual(isFinded, YES);
        NOTIFY
    }];
    WAIT
}

- (AVUser *)signUpRandomUser {
    AVUser *user  = [[AVUser alloc] init];

    user.username = [@"foo" stringByAppendingFormat:@"%ld", (long)arc4random()];
    user.password = [@"bar" stringByAppendingFormat:@"%ld", (long)arc4random()];

    NSError *error = nil;
    [user signUp:&error];

    XCTAssert(!error, @"%@", error);

    return user;
}

- (void)testGetRoles {
    AVUser *user = [self signUpRandomUser];
    AVRole *role = [AVRole roleWithName:[@"testRole" stringByAppendingFormat:@"%ld", (long)arc4random()]];

    AVACL *acl = [AVACL ACL];
    [acl setPublicReadAccess:YES];
    [acl setWriteAccess:YES forUser:user];

    role.ACL = acl;
    [role.users addObject:user];

    NSError *error1 = nil;
    [role save:&error1];

    XCTAssertTrue(error1 == nil, @"%@", error1);

    NSError *error2 = nil;
    NSArray<AVRole *> *roles = [user getRoles:&error2];

    XCTAssertTrue(error2 == nil, @"%@", error2);

    XCTAssertEqual(roles.count, 1);
    XCTAssertTrue([[[roles firstObject] objectId] isEqualToString:role.objectId]);

    [role delete];
    [user delete];
}

- (void)testSessionToken {
    AVUser *user = [self signUpRandomUser];
    XCTAssertTrue([user fetch]);
    XCTAssertNotNil(user.sessionToken);
}

- (void)testRefreshSessionToken {
    AVUser *user = [self signUpRandomUser];
    NSString *firstSessionToken = user.sessionToken;
    XCTAssertNotNil(firstSessionToken);

    [user refreshSessionTokenWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        XCTAssertTrue(succeeded);
        NSString *secondSessionToken = user.sessionToken;

        XCTAssertNotEqualObjects(firstSessionToken, secondSessionToken);
        XCTAssertNotNil(secondSessionToken);
        NOTIFY;
    }];
    WAIT;
}

- (void)testSocialAuth
{
    /* tools & constants */
    
    typedef void(^semaphoreBlock)(dispatch_semaphore_t);
    
    BOOL (^semaphoreSync)(semaphoreBlock) = ^BOOL(semaphoreBlock block)
    {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        
        block(semaphore);
        
        long num = dispatch_semaphore_wait(semaphore, dTimeout(10));
        
        BOOL isTimeout = (num != 0);
        
        return isTimeout;
    };
    
    NSString *weiboUid = @"12345678";
    
    NSString *weiboToken = @"87654321";
    
    NSDictionary *weiboAuthData = @{
                                    @"authData" : @{
                                            LeanCloudSocialPlatformWeiBo : @{
                                                    @"uid" : weiboUid,
                                                    @"access_token" : weiboToken
                                                    }
                                            }
                                    };
    __block AVUser *aUser = nil;
    
    /* 1 test invalid `authData` format */
    
    NSArray *_1_array_1 = @[
                            @{},
                            @{ @"authData" : @[] },
                            @{ @"authData" : @{} },
                            @{ @"authData" : @{ LeanCloudSocialPlatformWeiBo : @[] } },
                            @{ @"authData" : @{ LeanCloudSocialPlatformWeiBo : @{} } }
                            ];
    
    for (int i = 0; i < _1_array_1.count; i++) {
        
        NSDictionary *dic = _1_array_1[i];
        
        AVUserResultBlock block = ^(AVUser *user, NSError *error) {
            
            XCTAssertNil(user);
            
            XCTAssertNotNil(error);
        };
        
        [AVUser loginOrSignUpWithAuthData:dic
                                 platform:LeanCloudSocialPlatformWeiBo
                                    block:block];
    }
    
    /* 2 check using `authData` to login or signup */
    
    if (semaphoreSync( ^(dispatch_semaphore_t sp) {
        
        AVUserResultBlock block = ^(AVUser *user, NSError *error) {
            
            XCTAssertNotNil(user);
            
            XCTAssertNotNil(user.objectId);
            
            XCTAssertNotNil(user.sessionToken);
            
            XCTAssertNil(error);
            
            aUser = user;
            
            dispatch_semaphore_signal(sp);
        };
        
        [AVUser loginOrSignUpWithAuthData:weiboAuthData
                                     user:nil
                                 platform:LeanCloudSocialPlatformWeiBo
                                    queue:dispatch_queue_create("", nil)
                                    block:block];
    } )) {
        XCTFail(@"timeout");
    }
    
    /* 3 check associating & disassociating `authData` */
    
    if (semaphoreSync( ^(dispatch_semaphore_t sp) {

        AVUserResultBlock block = ^(AVUser *user, NSError *error) {

            XCTAssertNotNil(user);
            
            XCTAssertNil(user[authDataTag][LeanCloudSocialPlatformWeiBo]);

            XCTAssertNil(error);
            
            dispatch_semaphore_signal(sp);
        };

        [aUser disassociateWithPlatform:LeanCloudSocialPlatformWeiBo
                                  queue:dispatch_queue_create("", nil)
                                  block:block];
    } )) {
        XCTFail(@"timeout");
    }

    if (semaphoreSync( ^(dispatch_semaphore_t sp) {

        AVUserResultBlock block = ^(AVUser *user, NSError *error) {

            XCTAssertNotNil(user);
            
            XCTAssertNotNil(user[authDataTag][LeanCloudSocialPlatformWeiBo]);

            XCTAssertNil(error);
            
            dispatch_semaphore_signal(sp);
        };

        [aUser associateWithAuthData:weiboAuthData
                            platform:LeanCloudSocialPlatformWeiBo
                               queue:dispatch_queue_create("", nil)
                               block:block];
    } )) {
        XCTFail(@"timeout");
    }
    
}

@end
