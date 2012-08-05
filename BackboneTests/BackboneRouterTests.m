//
//  BackboneRouterTests.m
//  Backbone
//
//  Created by Edmond Leung on 8/4/12.
//  Copyright (c) 2012. All rights reserved.
//

#import <OCMock/OCMock.h>
#import "BackboneRouterTests.h"
#import "Backbone.h"
#import "MockRouter.h"

@implementation BackboneRouterTests

- (void)setUp {
  [super setUp];
  
  router_ = [[MockRouter alloc] init];
}

- (void)tearDown {
  [super tearDown];
}

- (void)testNoTrigger {
  [[Backbone history] navigate:@"search/news" options:0];
  STAssertEqualObjects(router_.query, nil, nil);
}

- (void)testRoutesSimple {
  [[Backbone history] navigate:@"search/news" options:BackboneHistoryTrigger];
  STAssertEqualObjects(router_.query, @"news", nil);
  STAssertEquals(router_.page, (NSUInteger)0, nil);
}

- (void)testRoutesTwoPart {
  [[Backbone history] navigate:@"search/nyc/p10" options:BackboneHistoryTrigger];
  STAssertEqualObjects(router_.query, @"nyc", nil);
  STAssertEquals(router_.page, (NSUInteger)10, nil);
}

- (void)testRoutePrecedence {
  [[Backbone history] navigate:@"contacts" options:BackboneHistoryTrigger];
  STAssertEqualObjects(router_.contact, @"index", nil);
  [[Backbone history] navigate:@"contacts/new" options:BackboneHistoryTrigger];
  STAssertEqualObjects(router_.contact, @"new", nil);
  [[Backbone history] navigate:@"contacts/foo" options:BackboneHistoryTrigger];
  STAssertEqualObjects(router_.contact, @"load", nil);
}

- (void)testNavigateIsNotCalledForIdenticalRoutes {
  [[Backbone history] navigate:@"counter" options:BackboneHistoryTrigger];
  [[Backbone history] navigate:@"counter" options:BackboneHistoryTrigger];
  STAssertEquals(router_.count, (NSUInteger)1, nil);
}

- (void)testRoutesSplats {
  [[Backbone history] navigate:@"splat/long-list/of/splatted_99args/end"
                       options:BackboneHistoryTrigger];
  STAssertEqualObjects(router_.args, @"long-list/of/splatted_99args", nil);
}

- (void)testRoutesComplex {
  [[Backbone history] navigate:@"one/two/three/complex-part/four/five/six/seven"
                       options:BackboneHistoryTrigger];
  STAssertEqualObjects(router_.first, @"one/two/three", nil);
  STAssertEqualObjects(router_.part, @"part", nil);
  STAssertEqualObjects(router_.rest, @"four/five/six/seven", nil);
}

- (void)testRoutesQuery {
  [[Backbone history] navigate:@"mandel?a=b&c=d"
                       options:BackboneHistoryTrigger];
  STAssertEqualObjects(router_.entity, @"mandel", nil);
  STAssertEqualObjects(router_.queryArgs, @"a=b&c=d", nil);
}

- (void)testRoutesAnything {
  [[Backbone history] navigate:@"doesnt-match-a-route"
                       options:BackboneHistoryTrigger];
  STAssertEqualObjects(router_.whatever, @"doesnt-match-a-route", nil);
}

- (void)testFiresEventWhenRouterDoesntHaveCallbackOnIt {
  __block NSUInteger counter = 0;
  
  [router_ on:@"route:noCallback" call:^(NSNotification *notification) {
    counter ++;
  }];
  [[Backbone history] navigate:@"noCallback" options:BackboneHistoryTrigger];
  STAssertEquals(counter, (NSUInteger)1, nil);
}

- (void)testRouteGetsPassedDecodedValues {
  [[Backbone history] navigate:@"has%2Fslash/complex-has%23hash/has%20space"
                       options:BackboneHistoryTrigger];
  STAssertEqualObjects(router_.first, @"has/slash", nil);
  STAssertEqualObjects(router_.part, @"has#hash", nil);
  STAssertEqualObjects(router_.rest, @"has space", nil);
}

- (void)testCorrectlyHandlesURLsWithPercent {
  [[Backbone history] navigate:@"search/fat%3A1.5%25"
                       options:BackboneHistoryTrigger];
  [[Backbone history] navigate:@"search/fat"
                       options:BackboneHistoryTrigger];
  STAssertEqualObjects(router_.query, @"fat", nil);
  STAssertEquals(router_.page, (NSUInteger)0, nil);
}

@end
