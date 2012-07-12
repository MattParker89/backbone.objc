//
//  BackboneTests.m
//  BackboneTests
//
//  Created by Edmond Leung on 5/10/12.
//  Copyright (c) 2012. All rights reserved.
//

#import "BackboneTests.h"
#import "Backbone.h"
#import "NSDictionary+Backbone.h"

@implementation BackboneTests

- (void)setUp {
  [super setUp];
  
  // Set-up code here.
}

- (void)tearDown {
  // Tear-down code here.
  
  [super tearDown];
}

- (void)testEncodingURLWithDictionary {
  NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInteger:1], @"foo",
                              [NSNumber numberWithInteger:2], @"bar",
                              nil];
  STAssertEqualObjects([dictionary encodedURL], @"foo=1&bar=2", nil);
}

- (void)testEncodingURLWithNestedDictionary {
  NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSDictionary
                               dictionaryWithObject:@"baz"
                               forKey:@"qux"], @"foo",
                              [NSNumber numberWithInteger:2], @"bar",
                              nil];
  STAssertEqualObjects([dictionary encodedURL], @"foo[qux]=baz&bar=2", nil); 
}

- (void)testEncodingURLWithArray {
  NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSArray
                               arrayWithObjects:@"foo", @"baz", nil], @"qux",
                              [NSNumber numberWithInteger:2], @"bar",
                              nil];
  STAssertEqualObjects([dictionary encodedURL], @"qux[]=foo&qux[]=baz&bar=2",
                       nil);
}

- (void)testEncodingURLWithNestedArray {
  NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSArray arrayWithObjects:
                               [NSArray arrayWithObject:@"foo"], @"baz", nil],
                              @"qux",
                              [NSNumber numberWithInteger:2], @"bar",
                              nil];
  STAssertEqualObjects([dictionary encodedURL], @"qux[0][]=foo&qux[]=baz&bar=2",
                       nil);
}

- (void)testEncodingURLSpecialCharacters {
  NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInteger:1], @"foo!",
                              [NSNumber numberWithInteger:2], @"bar &",
                              nil];
  STAssertEqualObjects([dictionary encodedURL], @"bar%20%26=2&foo%21=1", nil);
}

@end
