//
//  BackboneModelTests.m
//  BackboneTests
//
//  Created by Edmond Leung on 5/12/12.
//  Copyright (c) 2012. All rights reserved.
//

#import <OCMock/OCMock.h>
#import "BackboneModelTests.h"
#import "Backbone.h"
#import "MockModel.h"
#import "NSDictionary+Backbone.h"

@implementation BackboneModelTests

- (void)setUp {
  [super setUp];
  
  document_ = [[MockModel alloc] initWithAttributes:
               [NSDictionary dictionaryWithObjectsAndKeys:
                @"1-the-tempest", @"_id",
                @"The Tempest", @"title",
                @"Bill Shakespeare", @"author",
                nil]];
}

- (void)tearDown {
  document_ = nil;
  [super tearDown];
}

- (void)testInitializingWithAttributes {
  BackboneModel *model = [[BackboneModel alloc] initWithAttributes:
                          [NSDictionary 
                           dictionaryWithObject:[NSNumber numberWithInteger:1] 
                           forKey:@"one"]];
  
  STAssertEquals([[model get:@"one"] integerValue], 1, nil);
}

- (NSDictionary *)fakeParseAttributes:(NSDictionary *)attributes {
  NSMutableDictionary *parsedAttributed;
  
  parsedAttributed = [NSMutableDictionary dictionary];
  [parsedAttributed setObject:
   [NSNumber numberWithInteger:
    [[attributes objectForKey:@"value"] integerValue] + 1]
                       forKey:@"value"];
  
  return parsedAttributed;
}

- (void)testInitializingWithParsedAttributes {
  BackboneModel *model = [BackboneModel alloc];
  id mock = [OCMockObject partialMockForObject:model];
  [[[mock stub] andCall:@selector(fakeParseAttributes:)
               onObject:self] parse:[OCMArg any]];
  
  model = [model initWithAttributes:[NSDictionary
                                     dictionaryWithObject:
                                     [NSNumber numberWithInteger:1]
                                     forKey:@"value"]
                            options:BackboneParseAttributes];
  
  STAssertEquals([[model get:@"value"] integerValue], 2, nil);
}

- (void)testUrlWhenUsingUrlRootAndUriEncoding {
  BackboneModel *model = [[BackboneModel alloc] init];
  model.urlRoot = @"/collection";
  
  STAssertEqualObjects(model.url, @"/collection", nil);
  [model set:@"id" value:@"+1+"];
  STAssertEqualObjects(model.url, @"/collection/%2B1%2B", nil);
}

- (NSString *)fakeUrlRoot {
  return [NSString stringWithFormat:@"/nested/1/collection"];
}

- (void)testUrlWhenOverridingUrlRootPropertyToDetermineUrlRootAtRuntime {
  BackboneModel *model = [[BackboneModel alloc] init];
  id mock = [OCMockObject partialMockForObject:model];
  [[[mock stub] andCall:@selector(fakeUrlRoot)
               onObject:self] urlRoot];
  
  STAssertEqualObjects(model.url, @"/nested/1/collection", nil);
  [model set:@"id" value:[NSNumber numberWithInteger:2]];
  STAssertEqualObjects(model.url, @"/nested/1/collection/2", nil);
}

- (void)testClone {
  BackboneModel *a = [[BackboneModel alloc] initWithAttributes:
                      [NSDictionary dictionaryWithObjectsAndKeys:
                       [NSNumber numberWithInteger:1], @"foo",
                       [NSNumber numberWithInteger:2], @"bar",
                       [NSNumber numberWithInteger:3], @"baz",
                       nil]];
  BackboneModel *b = [a clone];
  
  STAssertEqualObjects([a get:@"foo"], [NSNumber numberWithInteger:1], nil);
  STAssertEqualObjects([a get:@"bar"], [NSNumber numberWithInteger:2], nil);
  STAssertEqualObjects([a get:@"baz" ], [NSNumber numberWithInteger:3], nil);
  STAssertEqualObjects([b get:@"foo"], [a get:@"foo"], 
                       @"Foo should be the same on the clone.");
  STAssertEqualObjects([b get:@"bar"], [a get:@"bar"], 
                       @"Bar should be the same on the clone.");
  STAssertEqualObjects([b get:@"baz"], [a get:@"baz"], 
                       @"Baz should be the same on the clone.");
  [a set:@"foo" value:[NSNumber numberWithInteger:100]];
  STAssertEqualObjects([a get:@"foo"], [NSNumber numberWithInteger:100], nil);
  STAssertEqualObjects([b get:@"foo"], [NSNumber numberWithInteger:1], 
                       @"Changing a parent attribute does not change the \
                       clone.");
}

- (void)testIsNew {
  BackboneModel *a = [[BackboneModel alloc] init];
  STAssertTrue([a isNew], @"it should be new");
  a = [[BackboneModel alloc] initWithAttributes:
       [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:-1]
                                   forKey:@"id"]];
  STAssertFalse([a isNew], @"any defined ID is legal, negative or positive");
  a = [[BackboneModel alloc] initWithAttributes:
       [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:0]
                                   forKey:@"id"]];
  STAssertFalse([a isNew], @"any defined ID is legal, including zero");
}

- (void)testGet {
  STAssertEqualObjects([document_ get:@"title"], @"The Tempest", nil);
  STAssertEqualObjects([document_ get:@"author"], @"Bill Shakespeare", nil);
}

- (void)testHas {
  BackboneModel *a = [[BackboneModel alloc] init];
  STAssertFalse([a has:@"name"], nil);
  [a set:@"name" value:@"Truth!"];
  STAssertTrue([a has:@"name"], nil);
  [a unset:@"name"];
  STAssertFalse([a has:@"name"], nil);
  [a set:@"name" value:[NSNull null]];
  STAssertFalse([a has:@"name"], nil);
}

- (void)fakeChange:(NSArray *)changes {
  STAssertTrue([changes containsObject:@"foo"],
              @"don't ignore values when unsetting");
}

- (void)testSetAndUnset {
  BackboneModel *a = [[BackboneModel alloc] initWithAttributes:
                      [NSDictionary dictionaryWithObjectsAndKeys:
                       @"id", @"id",
                       [NSNumber numberWithInteger:1], @"foo",
                       [NSNumber numberWithInteger:2], @"bar",
                       [NSNumber numberWithInteger:3], @"baz",
                       nil]];
  __block NSInteger counter = 0;
  [a on:@"change:foo" call:^(NSNotification *notification) {
    counter++;
  }];
  [a set:[NSDictionary dictionaryWithObject:
          [NSNumber numberWithInteger:2] forKey:@"foo"]];
  STAssertEqualObjects([a get:@"foo"], [NSNumber numberWithInteger:2],
                       @"Foo should have changed.");
  STAssertEquals(counter, 1,
                 @"Change count should have incremented.");
  [a set:[NSDictionary dictionaryWithObject:
          [NSNumber numberWithInteger:2] forKey:@"foo"]];
  
  // Set with value that is not new shouldn't fire change event.
  STAssertEqualObjects([a get:@"foo"], [NSNumber numberWithInteger:2],
                       @"Foo should NOT have changed.");
  STAssertEquals(counter, 1,
                 @"Change count should have NOT incremented.");
  
  [a unset:@"id"];
  STAssertNil(a.id, @"Unsetting the id should remove the id property.");
  
  [a unset:@"foo"];
  STAssertNil([a get:@"foo"], @"Foo should have changed");
  STAssertEquals(counter, 2,
                 @"Change count should have incremented for unset.");
  
  [a set:@"foo" value:[NSNumber numberWithInteger:1]];
  id mock = [OCMockObject partialMockForObject:a];
  [[[mock stub] andCall:@selector(fakeChange:)
               onObject:self] change:[OCMArg any]];
  [a unset:@"foo"];
}

- (void)testMultipleUnsets {
  BackboneModel *model = [[BackboneModel alloc] initWithAttributes:
                          [NSDictionary dictionaryWithObjectsAndKeys:
                           @"id", @"id",
                           [NSNumber numberWithInteger:1], @"a",
                           nil]];
  __block NSInteger counter = 0;
  [model on:@"change:a" call:^(NSNotification *notification) {
    counter++;
  }];
  [model set:@"a" value:[NSNumber numberWithInteger:2]];
  [model unset:@"a"];
  [model unset:@"a"];
  STAssertEquals(counter, 2,
                 @"Unset does not fire an event for missing attributes.");
}

- (void)testUnsetAndChangedAttributes {
  BackboneModel *model = [[BackboneModel alloc] initWithAttributes:
                          [NSDictionary dictionaryWithObjectsAndKeys:
                           @"id", @"id",
                           [NSNumber numberWithInteger:1], @"a",
                           nil]];
  [model unset:@"a" options:BackboneSetSilently];
  NSDictionary *changedAttributes = model.changedAttributes;
  STAssertNotNil([changedAttributes objectForKey:@"a"],
               @"changedAttributes should contain unset properties");
  
  changedAttributes = model.changedAttributes;
  STAssertNotNil([changedAttributes objectForKey:@"a"],
                 @"changedAttributes should contain unset properties when\
                 running changedAttributes again after an unset.");
}

- (void)testUsingANonDefaultIdAttribute {
  MockModel *model = [[MockModel alloc] initWithAttributes:
                          [NSDictionary dictionaryWithObjectsAndKeys:
                           @"eye-dee", @"id",
                           [NSNumber numberWithInteger:25], @"_id",
                           @"Model", @"title",
                           nil]];
  STAssertEqualObjects([model get:@"id"], @"eye-dee", nil);
  STAssertEquals([model.id integerValue], 25, nil);
  STAssertFalse([model isNew], nil);
  [model unset:@"_id"];
  STAssertNil(model.id, nil);
  STAssertTrue([model isNew], nil);
}

- (void)testSettingAnEmptyString {
  BackboneModel *model = [[BackboneModel alloc] initWithAttributes:
                          [NSDictionary dictionaryWithObject:@"model"
                                                      forKey:@"name"]];
  [model set:@"name" value:@""];
  STAssertEqualObjects([model get:@"name"], @"", nil);
}

- (void)testClear {
  __block BOOL changed = NO;
  BackboneModel *model = [[BackboneModel alloc] initWithAttributes:
                          [NSDictionary dictionaryWithObjectsAndKeys:
                           [NSNumber numberWithInteger:1], @"id",
                           @"model", @"name",
                           nil]];
  
  [model on:@"change:name" call:^(NSNotification *notification) {
    changed = YES;
  }];
  [model on:@"change" call:^(NSNotification *notification) {
    STAssertNotNil([model.changedAttributes objectForKey:@"name"], nil);
  }];
  
  [model clear];
  
  STAssertTrue(changed, nil);
  STAssertNil([model get:@"name"], nil);
}

- (void)testDefaults {
  MockModel *model = [[MockModel alloc] initWithAttributes:
                      [NSDictionary dictionaryWithObject:[NSNull null] 
                                                  forKey:@"two"]];
  STAssertEquals([[model get:@"one"] integerValue], 1, nil);
  STAssertEqualObjects([model get:@"two"], [NSNull null], nil);
}

- (void)testClearHasChangedChangedAttributesPreviousAndPreviousAttributes {
  BackboneModel *model = [[BackboneModel alloc] initWithAttributes:
                          [NSDictionary dictionaryWithObjectsAndKeys:
                           @"Tim", @"name",
                           [NSNumber numberWithInteger:10], @"age",
                           nil]];
  
  STAssertNil(model.changedAttributes, nil);
  
  [model on:@"change" call:^(NSNotification *notification) {
    STAssertTrue([model hasChanged:@"name"], @"name changed");
    STAssertFalse([model hasChanged:@"age"], @"age did not change");
    
    STAssertEquals(model.changedAttributes.allKeys.count, (NSUInteger)1, nil);
    STAssertEqualObjects([model.changedAttributes objectForKey:@"name"], @"Rob",
                         @"changedAttributes returns the changed attrs");
    STAssertEqualObjects([model previous:@"name"], @"Tim", nil);
    
    STAssertEquals(model.previousAttributes.allKeys.count, (NSUInteger)2, nil);
    STAssertEqualObjects([model.previousAttributes objectForKey:@"name"],
                         @"Tim", nil);
    STAssertEqualObjects([model.previousAttributes objectForKey:@"age"],
                         [NSNumber numberWithInteger:10], nil);
  }];
  
  STAssertFalse([model hasChanged], nil);
  STAssertFalse([model hasChanged:nil], nil);
  [model set:@"name" value:@"Rob" options:BackboneSetSilently];
  STAssertTrue([model hasChanged], nil);
  STAssertTrue([model hasChanged:nil], nil);
  STAssertTrue([model hasChanged:@"name"], nil);
  [model change];
  STAssertEqualObjects([model previous:@"name"], @"Rob", nil);
}

- (void)testChangedAttributes {
  BackboneModel *model = [[BackboneModel alloc] initWithAttributes:
                          [NSDictionary dictionaryWithObjectsAndKeys:
                           @"a", @"a", @"b", @"b",
                           nil]];
  STAssertNil(model.changedAttributes, nil);
  STAssertNil([model changedAttributes:
               [NSDictionary dictionaryWithObject:@"a" forKey:@"a"]], nil);
  STAssertEqualObjects([[model changedAttributes:
                        [NSDictionary dictionaryWithObject:@"b" forKey:@"a"]] 
                        objectForKey:@"a"],
                       @"b", nil);
}

- (void)testChangeAfterInitialize {
  __block NSInteger counter = 0;
  NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInteger:1], @"id",
                              @"c", @"label",
                              nil];
  BackboneModel *obj = [[BackboneModel alloc]
                        initWithAttributes:attributes];
  [obj on:@"change" call:^(NSNotification *notification) {
    counter++;
  }];
  [obj set:attributes];
  STAssertEquals(counter, 0, nil);
}

- (void)testSaveWithinChangeEvent {
  MockModel *model = [[MockModel alloc] initWithAttributes:
                      [NSDictionary dictionaryWithObjectsAndKeys:
                       @"Taylor", @"firstName",
                       @"Swift", @"lastName",
                           nil]];
  [model on:@"change" call:^(NSNotification *notification) {
    [model save];
    STAssertEquals([[MockModel lastRequest] objectForKey:@"model"], model, nil);
  }];
  [model set:@"lastName" value:@"Hicks"];
}

- (void)testValidateAfterSave {
  MockModel *model = [[MockModel alloc] init];
  [model save];
  STAssertTrue(model.validated, nil);
}

- (void)testIsValid {
  MockModel *model = [[MockModel alloc] initWithAttributes:
                      [NSDictionary 
                       dictionaryWithObject:[NSNumber numberWithBool:YES]
                       forKey:@"valid"]];
  STAssertTrue([model isValid], nil);
  STAssertFalse([model set:@"valid" value:[NSNumber numberWithBool:NO]], nil);
  STAssertTrue([model isValid], nil);
  STAssertTrue([model set:@"valid"
                     value:[NSNumber numberWithBool:NO]
                   options:BackboneSetSilently], nil);
  STAssertFalse([model isValid], nil);
}

- (void)testSave {
  [document_ save:[NSDictionary dictionaryWithObject:@"Henry V" forKey:@"title"]
          options:0
  successCallback:nil
    errorCallback:nil];
  
  NSDictionary *lastRequest = [MockModel lastRequest];
  STAssertEquals([[lastRequest objectForKey:@"method"] integerValue],
                 BackboneSyncCRUDMethodUpdate, nil);
  STAssertEquals([lastRequest objectForKey:@"model"], document_, nil);
}

- (void)testFetch {
  [document_ fetch];
  
  NSDictionary *lastRequest = [MockModel lastRequest];
  STAssertEquals([[lastRequest objectForKey:@"method"] integerValue],
                 BackboneSyncCRUDMethodRead, nil);
  STAssertEquals([lastRequest objectForKey:@"model"], document_, nil);
}

- (void)testDestroy {
  [document_ destroy];
  
  NSDictionary *lastRequest = [MockModel lastRequest];
  STAssertEquals([[lastRequest objectForKey:@"method"] integerValue],
                 BackboneSyncCRUDMethodDelete, nil);
  STAssertEquals([lastRequest objectForKey:@"model"], document_, nil);
  
  BackboneModel *newModel = [[BackboneModel alloc] init];
  STAssertFalse([newModel destroy], nil);
}

- (void)testNonPersistedDestroy {
  MockModel *a = [[MockModel alloc] initWithAttributes:
                  [NSDictionary dictionaryWithObjectsAndKeys:
                   [NSNumber numberWithInteger:1], @"foo",
                   [NSNumber numberWithInteger:2], @"bar",
                   [NSNumber numberWithInteger:3], @"baz",
                   nil]];
  [MockModel clearLastRequest];
  [a destroy];
  STAssertNil([MockModel lastRequest],
              @"non-persisted model should not call sync");
}

- (void)testValidateOnUnsetAndClear {
  MockModel *model = [[MockModel alloc] initWithAttributes:
                      [NSDictionary
                       dictionaryWithObject:[NSNumber numberWithBool:YES]
                       forKey:@"valid"]];
  STAssertFalse([model unset:@"valid"], nil);
  STAssertFalse([model clear], nil);
}

- (void)testValidateWithErrorCallback {
  __block NSError *lastError;
  __block BOOL boundError = false;
  
  id callback = ^(id subject, NSError *error) {
    lastError = error;
  };
  
  MockModel *model = [[MockModel alloc] init];
  [model on:@"error" call:^(NSNotification *notification) {
    boundError = YES;
  }];
  STAssertTrue([model set:@"a"
                    value:[NSNumber numberWithInteger:100]
                  options:0
            errorCallback:callback], nil);
  STAssertEquals([[model get:@"a"] integerValue], 100, nil);
  STAssertNil(lastError, nil);
  STAssertFalse(boundError, nil);
  STAssertFalse([model set:@"valid"
                     value:[NSNumber numberWithBool:NO]
                   options:0
             errorCallback:callback], nil);
  STAssertEquals([[model get:@"a"] integerValue], 100, nil);
  STAssertEquals([lastError.userInfo objectForKey:@"valid"], @"Invalid", nil);
}

- (void)testDefaultAlwaysExtendsAttributes {
  MockModel *providedAttributes = [[MockModel alloc] initWithAttributes:
                                   [NSDictionary dictionary]];
  STAssertEquals([[providedAttributes get:@"one"] integerValue], 1, nil);
  MockModel *emptyAttributes = [[MockModel alloc] initWithAttributes:nil];
  STAssertEquals([[emptyAttributes get:@"one"] integerValue], 1, nil);
}

- (void)testNestedChangeEventsDontClubberPreviousAttributes {
  BackboneModel *a = [[BackboneModel alloc] init];
  [a on:@"change:state" call:^(NSNotification *notification) {
    STAssertNil([a previous:@"state"], nil);
    STAssertEqualObjects([notification.object objectAtIndex:1], @"hello", nil);
    [a set:@"other" value:@"whatever"];
  }];
  
  BackboneModel *b = [[BackboneModel alloc] initWithAttributes:
                      [NSDictionary dictionaryWithObject:a forKey:@"a"]];
  [[b get:@"a"] on:@"change:state" call:^(NSNotification *notification) {
    STAssertNil([a previous:@"state"], nil);
    STAssertEqualObjects([notification.object objectAtIndex:1], @"hello", nil);
  }];
  [a set:@"state" value:@"hello"];
}

- (void)testChangeAttributeCallbacksShouldFireAfterAllChangesHaveOccurred {
  BackboneModel *model = [[BackboneModel alloc] init];
  
  id assertion = ^(NSNotification *notification) {
    STAssertEqualObjects([model get:@"a"], @"a", nil);
    STAssertEqualObjects([model get:@"b"], @"b", nil);
    STAssertEqualObjects([model get:@"c"], @"c", nil);
  };
  
  [model on:@"change:a" call:assertion];
  [model on:@"change:b" call:assertion];
  [model on:@"change:c" call:assertion];
  
  [model set:[NSDictionary dictionaryWithObjectsAndKeys:
              @"a", @"a", @"b", @"b", @"c", @"c", nil]];
}

- (void)testSettingValueRegardlessOfEqualityAndChange {
  BackboneModel *model = [[BackboneModel alloc] initWithAttributes:
                          [NSDictionary dictionaryWithObject:[NSArray array]
                                                      forKey:@"x"]];
  NSArray *a = [NSArray array];
  [model set:@"x" value:a];
  STAssertTrue([model get:@"x"] == a, nil);
}

- (void)testChangeFiresChangeAttributeEvents {
  __block NSInteger counter = 0;
  BackboneModel *model = [[BackboneModel alloc] initWithAttributes:
                          [NSDictionary dictionaryWithObject:
                           [NSNumber numberWithInteger:1]
                                                      forKey:@"x"]];
  [model set:@"x"
       value:[NSNumber numberWithInteger:2]
     options:BackboneSetSilently];
  [model on:@"change:x" call:^(NSNotification *notification) {
    counter++;
  }];
  [model change];
  STAssertTrue(counter > 0, nil);
}

- (void)testHasChangedIsFalseAfterOriginalValuesAreSet {
  BackboneModel *model = [[BackboneModel alloc] initWithAttributes:
                          [NSDictionary dictionaryWithObject:
                           [NSNumber numberWithInteger:1]
                                                      forKey:@"x"]];
  [model on:@"change:x" call:^(NSNotification *notification) {
    STAssertTrue(NO, nil);
  }];
  [model set:@"x"
       value:[NSNumber numberWithInteger:2]
     options:BackboneSetSilently];
  STAssertTrue([model hasChanged], nil);
  [model set:@"x"
       value:[NSNumber numberWithInteger:1]
     options:BackboneSetSilently];
  STAssertFalse([model hasChanged], nil); 
}

- (void)testSaveWithWaitSuccessWithoutValidate {
  MockModel *model = [[MockModel alloc] init];
  [model save:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
                                          forKey:@"x"]
      options:BackboneSyncWait successCallback:nil errorCallback:nil];
  STAssertTrue([[MockModel lastRequest] objectForKey:@"model"] == model, nil);
}

- (void)testRetrievingAttributeWithGetter {
  MockModel *model = [[MockModel alloc] init];
  STAssertEquals([model.one integerValue], 1, nil);
  [model set:@"one" value:[NSNumber numberWithInteger:100]];
  STAssertEquals([model.one integerValue], 100, nil);
}

- (void)testSaveWithWaitValidatesAttributes {
  MockModel *model = [[MockModel alloc] init];
  [model save:[NSDictionary dictionaryWithObject:
               [NSNumber numberWithInteger:1] forKey:@"x"]
      options:BackboneSyncWait];
  STAssertTrue(model.validated, nil);
}

- (void)testNestedSetDuringChangeAttributesEvent {
  NSArray *expectedEvents;
  NSMutableArray *events = [NSMutableArray array];
  BackboneModel *model = [[BackboneModel alloc] init];
  [model on:@"all" call:^(NSNotification *notification) {
    [events addObject:notification.name];
  }];
  [model on:@"change" call:^(NSNotification *notification) {
    [model set:@"z"
         value:[NSNumber numberWithBool:YES]
       options:BackboneSetSilently];
  }];
  [model on:@"change:x" call:^(NSNotification *notification) {
    [model set:@"y" value:[NSNumber numberWithBool:YES]];
  }];
  [model set:@"x" value:[NSNumber numberWithBool:YES]];
  expectedEvents = [NSArray arrayWithObjects:
                    @"change:y", @"change:x", @"change", nil];
  STAssertTrue([events isEqualToArray:expectedEvents], nil);
  [events removeAllObjects];
  [model change];
  expectedEvents = [NSArray arrayWithObjects:@"change:z", @"change", nil];
  STAssertTrue([events isEqualToArray:expectedEvents], nil);
}

- (void)testNestedChangeOnlyFiresOnce {
  __block NSInteger counter = 0;
  BackboneModel *model = [[BackboneModel alloc] init];
  [model on:@"change" call:^(NSNotification *notification) {
    counter++;
    [model change];
  }];
  [model set:@"x" value:[NSNumber numberWithBool:YES]];
  STAssertEquals(counter, 1, nil);
}

- (void)testNoChangeEventIfNoChanges {
  BackboneModel *model = [[BackboneModel alloc] init];
  [model on:@"change" call:^(NSNotification *notification) {
    STAssertFalse(YES, nil);
  }];
  [model change];
}

- (void)testedNestedSetDuringChange {
  __block NSInteger counter = 0;
  BackboneModel *model = [[BackboneModel alloc] init];
  [model on:@"change" call:^(NSNotification *notification) {
    switch (counter++) {
      case 0:
        STAssertEqualObjects(model.changedAttributes,
                     [NSDictionary dictionaryWithObject:
                      [NSNumber numberWithBool:YES] forKey:@"x"], nil);
        STAssertNil([model previous:@"x"], nil);
        [model set:@"y" value:[NSNumber numberWithBool:YES]];
        break;
      case 1:
        STAssertEqualObjects(model.changedAttributes,
                     [NSDictionary dictionaryWithObject:
                      [NSNumber numberWithBool:YES] forKey:@"y"], nil);
        STAssertTrue([[model previous:@"x"] boolValue], nil);
        [model set:@"z" value:[NSNumber numberWithBool:YES]];
        break;
      case 2:
        STAssertEqualObjects(model.changedAttributes,
                     [NSDictionary dictionaryWithObject:
                      [NSNumber numberWithBool:YES] forKey:@"z"], nil);
        STAssertTrue([[model previous:@"y"] boolValue], nil);
        break;
    }
  }];
  [model set:@"x" value:[NSNumber numberWithBool:YES]];
}

- (void)testedNestedChangeWithSilent {
  __block NSInteger counter = 0;
  __block BOOL yChanged = NO;
  __block NSDictionary *expectedChanged;
  BackboneModel *model = [[BackboneModel alloc] init];
  [model on:@"change:y" call:^(NSNotification *notification) {
    yChanged = YES;
  }];
  [model on:@"change" call:^(NSNotification *notification) {
    switch (counter++) {
      case 0:
        STAssertEqualObjects(model.changedAttributes,
                             [NSDictionary dictionaryWithObject:
                              [NSNumber numberWithBool:YES] forKey:@"x"], nil);
        [model set:@"y"
             value:[NSNumber numberWithBool:YES]
           options:BackboneSetSilently];
        break;
      case 1:
        expectedChanged = [NSDictionary dictionaryWithObjectsAndKeys:
                           [NSNumber numberWithBool:YES], @"y",
                           [NSNumber numberWithBool:YES], @"z",
                           nil];
        STAssertEqualObjects(model.changedAttributes, expectedChanged, nil);
        break;
      default:
        STAssertTrue(NO, nil);
    }
  }];
  [model set:@"x" value:[NSNumber numberWithBool:YES]];
  [model set:@"z" value:[NSNumber numberWithBool:YES]];
  STAssertTrue(yChanged, nil);
}

- (void)testedNestedChangeAttributeEventWithSilent {
  __block NSInteger counter = 0;
  BackboneModel *model = [[BackboneModel alloc] init];
  [model on:@"change:y" call:^(NSNotification *notification) {
    counter++;
  }];
  [model on:@"change" call:^(NSNotification *notification) {
    [model set:@"y"
         value:[NSNumber numberWithBool:YES]
       options:BackboneSetSilently];
    [model set:@"z" value:[NSNumber numberWithBool:YES]];
  }];
  [model set:@"x" value:[NSNumber numberWithBool:YES]];
  STAssertEquals(counter, 1, nil);
}

- (void)testedMultipleNestedChangesWithSilent {
  BackboneModel *model = [[BackboneModel alloc] init];
  [model on:@"change:x" call:^(NSNotification *notification) {
    [model set:@"y"
         value:[NSNumber numberWithInteger:1]
       options:BackboneSetSilently];
    [model set:@"y" value:[NSNumber numberWithInteger:2]];
  }];
  [model on:@"change:y" call:^(NSNotification *notification) {
    STAssertEquals([[notification.object objectAtIndex:1] integerValue], 2, nil);
  }];
  [model set:@"x" value:[NSNumber numberWithBool:YES]];
  [model change];
}

- (void)testNestedSetMultipleTimes {
  __block NSInteger counter = 0;
  BackboneModel *model = [[BackboneModel alloc] init];
  [model on:@"change:b" call:^(NSNotification *notification) {
    counter++;
  }];
  [model on:@"change:a" call:^(NSNotification *notification) {
    [model set:@"b" value:[NSNumber numberWithBool:YES]];
    [model set:@"b" value:[NSNumber numberWithBool:YES]];
  }];
  [model set:@"a" value:[NSNumber numberWithBool:YES]];
  STAssertEquals(counter, 1, nil);
}

- (void)testIsValidReturnsTrueInAbsenceOfValidate {
  BackboneModel *model = [[BackboneModel alloc] init];
  STAssertTrue([model isValid], nil);
}

@end
