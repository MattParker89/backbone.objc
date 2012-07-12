//
//  BackboneCollectionTests.m
//  Backbone
//
//  Created by Edmond Leung on 7/10/12.
//  Copyright (c) 2012. All rights reserved.
//

#import <OCMock/OCMock.h>
#import "BackboneCollectionTests.h"
#import "Backbone.h"
#import "MockModel.h"
#import "MockCollection.h"

@implementation BackboneCollectionTests

- (void)setUp {
  [super setUp];
  
  a_ = [[BackboneModel alloc] initWithAttributes:
        [NSDictionary dictionaryWithObjectsAndKeys:
         [NSNumber numberWithInteger:3], @"id",
         @"a", @"label",
         nil]];
  b_ = [[BackboneModel alloc] initWithAttributes:
        [NSDictionary dictionaryWithObjectsAndKeys:
         [NSNumber numberWithInteger:2], @"id",
         @"b", @"label",
         nil]];
  c_ = [[BackboneModel alloc] initWithAttributes:
        [NSDictionary dictionaryWithObjectsAndKeys:
         [NSNumber numberWithInteger:1], @"id",
         @"c", @"label",
         nil]];
  d_ = [[BackboneModel alloc] initWithAttributes:
        [NSDictionary dictionaryWithObjectsAndKeys:
         [NSNumber numberWithInteger:0], @"id",
         @"d", @"label",
         nil]];
  e_ = nil;
  
  col_ = [[MockCollection alloc] initWithModels:
          [NSArray arrayWithObjects:a_, b_, c_, d_, nil]];
  otherCol_ =
    [[BackboneCollection alloc] initWithModel:[MockModel class] models:nil];
}

- (void)tearDown {
  a_ = b_ = c_ = d_ = e_ = nil;
  col_ = otherCol_ = nil;
  [super tearDown];
}

- (void)testNewAndSort {
  STAssertEquals([col_ objectAtIndex:0], a_, @"a should be first");
  STAssertEquals([col_ lastObject], d_, @"d should be last");
  col_.comparator = ^(id a, id b) {
    return [[b id] compare:[a id]];
  };
  [col_ sort];
  STAssertEquals([col_ objectAtIndex:0], a_, @"a should be first");
  STAssertEquals([col_ lastObject], d_, @"d should be last");
  col_.comparator =  ^(id a, id b) {
    return [[a id] compare:[b id]];
  };
  [col_ sort];
  STAssertEquals([col_ objectAtIndex:0], d_, @"d should be first");
  STAssertEquals([col_ lastObject], a_, @"a should be last");
  STAssertEquals(col_.count, (NSUInteger)4, nil);
}

- (void)testGetAndGetByCid {
  STAssertEquals([col_ get:[NSNumber numberWithInteger:0]], d_, nil);
  STAssertEquals([col_ get:[NSNumber numberWithInteger:2]], b_, nil);
  STAssertEquals([col_ getByCid:[[col_ objectAtIndex:0] cid]],
                 [col_ objectAtIndex:0], nil);
}

- (void)testGetWithNonDefaultIds {
  BackboneCollection *col = [[BackboneCollection alloc] init];
  MockModel* model = [[MockModel alloc] initWithAttributes:
                      [NSDictionary 
                       dictionaryWithObject:[NSNumber numberWithInteger:100]
                       forKey:@"_id"]];
  [col push:model];
  STAssertEquals([col get:[NSNumber numberWithInteger:100]], model, nil);
  [model set:@"_id" value:[NSNumber numberWithInteger:101]];
  STAssertEquals([col get:[NSNumber numberWithInteger:101]], model, nil);
}

- (void)testUpdateIndexWithIdChanges {
  BackboneCollection *col = [[BackboneCollection alloc] init];
  [col addModels:[NSArray arrayWithObjects:
                  [NSDictionary dictionaryWithObjectsAndKeys:
                   [NSNumber numberWithInteger:0], @"id",
                   @"one", @"name", nil],
                  [NSDictionary dictionaryWithObjectsAndKeys:
                   [NSNumber numberWithInteger:1], @"id",
                   @"two", @"name", nil],
                  nil]];
  BackboneModel *one = [col get:[NSNumber numberWithInteger:0]];
  STAssertEqualObjects([one get:@"name"], @"one", nil);
  [one set:@"id" value:[NSNumber numberWithInteger:101]];
  STAssertNil([col get:[NSNumber numberWithInteger:0]], nil);
  STAssertEqualObjects([[col get:[NSNumber numberWithInteger:101]] get:@"name"],
                       @"one", nil);
}

- (void)testAt {
  STAssertEquals([col_ at:2], c_, nil);
}

- (void)testPluck {
  STAssertEqualObjects([[col_ pluck:@"label"] componentsJoinedByString:@" "],
                       @"a b c d", nil);
}

- (void)testAdd {
  __block NSString *added;
  __block BOOL secondAdded;
  
  added = nil;
  secondAdded = NO;
  
  e_ = [[BackboneModel alloc] initWithAttributes:
        [NSDictionary dictionaryWithObjectsAndKeys:
         [NSNumber numberWithInteger:10], @"id", 
         @"e", @"label", nil]];
  [otherCol_ add:e_];
  [otherCol_ on:@"add" call:^(NSNotification *notification) {
    secondAdded = YES;
  }];
  [col_ on:@"add" call:^(NSNotification *notification) {
    added = [[notification.object objectAtIndex:0] get:@"label"];
  }];
  [col_ add:e_];
  STAssertEqualObjects(added, @"e", nil);
  STAssertEquals(col_.count, (NSUInteger)5, nil);
  STAssertEquals([col_ lastObject], e_, nil);
  STAssertEquals(otherCol_.count, (NSUInteger)1, nil);
  STAssertFalse(secondAdded, nil);
  
  BackboneModel *f = [[BackboneModel alloc] initWithAttributes:
                      [NSDictionary dictionaryWithObjectsAndKeys:
                       [NSNumber numberWithInteger:20], @"id",
                       @"f", @"label",
                       nil]];
  BackboneModel *g = [[BackboneModel alloc] initWithAttributes:
                      [NSDictionary dictionaryWithObjectsAndKeys:
                       [NSNumber numberWithInteger:21], @"id",
                       @"g", @"label",
                       nil]];
  BackboneModel *h = [[BackboneModel alloc] initWithAttributes:
                      [NSDictionary dictionaryWithObjectsAndKeys:
                       [NSNumber numberWithInteger:22], @"id",
                       @"h", @"label",
                       nil]];
  BackboneCollection *atCol = [[BackboneCollection alloc] initWithModels:
                               [NSArray arrayWithObjects:f, g, h, nil]];
  STAssertEquals(atCol.count, (NSUInteger)3, nil);
  [atCol add:e_ at:1];
  STAssertEquals(atCol.count, (NSUInteger)4, nil);
  STAssertEquals([atCol at:1], e_, nil);
  STAssertEquals([atCol lastObject], h, nil);
}

- (void)testAddingMultipleModels {
  BackboneCollection *col = [[BackboneCollection alloc] initWithModels:
                             [NSArray arrayWithObjects:
                              [NSDictionary dictionaryWithObject:
                               [NSNumber numberWithInteger:0] forKey:@"at"],
                              [NSDictionary dictionaryWithObject:
                               [NSNumber numberWithInteger:1] forKey:@"at"],
                              [NSDictionary dictionaryWithObject:
                               [NSNumber numberWithInteger:9] forKey:@"at"],
                              nil]];
  [col addModels:[NSArray arrayWithObjects:
                  [NSDictionary dictionaryWithObject:
                   [NSNumber numberWithInteger:2] forKey:@"at"],
                  [NSDictionary dictionaryWithObject:
                   [NSNumber numberWithInteger:3] forKey:@"at"],
                  [NSDictionary dictionaryWithObject:
                   [NSNumber numberWithInteger:4] forKey:@"at"],
                  [NSDictionary dictionaryWithObject:
                   [NSNumber numberWithInteger:5] forKey:@"at"],
                  [NSDictionary dictionaryWithObject:
                   [NSNumber numberWithInteger:6] forKey:@"at"],
                  [NSDictionary dictionaryWithObject:
                   [NSNumber numberWithInteger:7] forKey:@"at"],
                  [NSDictionary dictionaryWithObject:
                   [NSNumber numberWithInteger:8] forKey:@"at"],
                  nil]
              at:2];
  for (NSUInteger i = 0; i <= 5; i++) {
    STAssertEqualObjects([[col at:i] get:@"at"],
                         [NSNumber numberWithInteger:i], nil);
  }
}

- (void)testCannotAddModelToCollectionTwice {
  BackboneCollection *col = [[BackboneCollection alloc] initWithModels:
                             [NSArray arrayWithObjects:
                              [NSDictionary dictionaryWithObject:@"1"
                                                          forKey:@"id"],
                              [NSDictionary dictionaryWithObject:@"2"
                                                          forKey:@"id"],
                              [NSDictionary dictionaryWithObject:@"1"
                                                          forKey:@"id"],
                              [NSDictionary dictionaryWithObject:@"2"
                                                          forKey:@"id"],
                              [NSDictionary dictionaryWithObject:@"3"
                                                          forKey:@"id"],
                              nil]];
  STAssertEqualObjects([[col pluck:@"id"] componentsJoinedByString:@" "],
                       @"1 2 3", nil);
}

- (void)testCannotAddDifferentModelsWithSameIdToCollectionTwice {
  BackboneCollection *col = [[BackboneCollection alloc] init];
  [col unshift:[NSDictionary
                dictionaryWithObject:[NSNumber numberWithInteger:101]
                forKey:@"id"]];
  [col add:[NSDictionary
            dictionaryWithObject:[NSNumber numberWithInteger:101]
            forKey:@"id"]];
  STAssertEquals(col.count, (NSUInteger)1, nil);
}

- (void)testAddingModelToMultipleCollections {
  __block NSUInteger counter = 0;
  
  BackboneCollection *colE = [[BackboneCollection alloc] init];
  BackboneCollection *colF = [[BackboneCollection alloc] init];
  
  BackboneModel *e = [[BackboneModel alloc] initWithAttributes:
                      [NSDictionary dictionaryWithObjectsAndKeys:
                       [NSNumber numberWithInteger:10], @"id",
                       @"e", @"label", nil]];
  [e on:@"add" call:^(NSNotification *notification) {
    BackboneModel *model = [notification.object objectAtIndex:0];
    BackboneCollection *collection = [notification.object objectAtIndex:1];
    
    counter ++;
    
    STAssertEquals(e, model, nil);
    if (counter > 1) {
      STAssertEquals(collection, colF, nil);
    } else {
      STAssertEquals(collection, colE, nil);
    }
  }];
  
  [colE on:@"add" call:^(NSNotification *notification) {
    BackboneModel *model = [notification.object objectAtIndex:0];
    BackboneCollection *collection = [notification.object objectAtIndex:1];
    
    STAssertEquals(e, model, nil);
    STAssertEquals(colE, collection, nil);
  }];
  
  [colF on:@"add" call:^(NSNotification *notification) {
    BackboneModel *model = [notification.object objectAtIndex:0];
    BackboneCollection *collection = [notification.object objectAtIndex:1];
    
    STAssertEquals(e, model, nil);
    STAssertEquals(colF, collection, nil);
  }];
  
  [colE add:e];
  STAssertEquals(e.collection, colE, nil);
  [colF add:e];
  STAssertEquals(e.collection, colE, nil);
}

- (void)testAddingModelWithParse {
  BackboneCollection *col =
    [[BackboneCollection alloc] initWithModel:[MockModel class] models:nil];
  [col add:[NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:1]
                                       forKey:@"value"]
   options:BackboneParseAttributes];
  STAssertEquals([[[col at:0] get:@"value"] integerValue], 2, nil);
}

- (void)testAddingModelToCollectionWithSortStyleComparator {
  BackboneCollection *col = [[BackboneCollection alloc] init];
  col.comparator = ^(id a, id b) {
    return [[a get:@"name"] compare:[b get:@"name"]];
  };
  BackboneModel *tom = [[BackboneModel alloc] initWithAttributes:
                        [NSDictionary dictionaryWithObject:@"Tom"
                                                    forKey:@"name"]];
  BackboneModel *rob = [[BackboneModel alloc] initWithAttributes:
                        [NSDictionary dictionaryWithObject:@"Rob"
                                                    forKey:@"name"]];
  BackboneModel *tim = [[BackboneModel alloc] initWithAttributes:
                        [NSDictionary dictionaryWithObject:@"Tim"
                                                    forKey:@"name"]];
  [col add:tom];
  [col add:rob];
  [col add:tim];
  STAssertEquals([col indexOfObject:rob], (NSUInteger)0, nil);
  STAssertEquals([col indexOfObject:tim], (NSUInteger)1, nil);
  STAssertEquals([col indexOfObject:tom], (NSUInteger)2, nil);
}

- (void)testRemove {
  __block NSString *removed = nil;
  __block BOOL otherRemoved = NO;
  
  [col_ on:@"remove" call:^(NSNotification *notification) {
    BackboneModel *model = [notification.object objectAtIndex:0];
    NSUInteger index = [[notification.object
                         objectAtIndex:3] unsignedIntegerValue];
    removed = [model get:@"label"];
    STAssertEquals(index, (NSUInteger)3, nil);
  }];
  
  [otherCol_ on:@"remove" call:^(NSNotification *notification) {
    otherRemoved = YES;
  }];
  
  [col_ remove:d_];
  STAssertEqualObjects(removed, @"d", nil);
  STAssertEquals(col_.count, (NSUInteger)3, nil);
  STAssertEquals([col_ objectAtIndex:0], a_, nil);
  STAssertFalse(otherRemoved, nil);
}

- (void)testShiftAndPop {
  BackboneCollection *col = [[BackboneCollection alloc] initWithModels:
                             [NSArray arrayWithObjects:
                              [NSDictionary dictionaryWithObject:@"a"
                                                          forKey:@"a"],
                              [NSDictionary dictionaryWithObject:@"b"
                                                          forKey:@"b"],
                              [NSDictionary dictionaryWithObject:@"c"
                                                          forKey:@"c"],
                              nil]]; 
  STAssertEqualObjects([[col shift] get:@"a"], @"a", nil);
  STAssertEqualObjects([[col pop] get:@"c"], @"c", nil);
}

- (void)testEventsAreUnboundOnRemove {
  __block NSUInteger counter = 0;
  BackboneModel *dj = [[BackboneModel alloc] init];
  BackboneCollection *emcees = [[BackboneCollection alloc]
                                initWithModels:[NSArray arrayWithObject:dj]];
  [emcees on:@"change" call:^(NSNotification *notification) {
    counter ++;
  }];
  [dj set:@"name" value:@"Kool"];
  STAssertEquals(counter, (NSUInteger)1, nil);
  [emcees reset:[NSArray array]];
  STAssertNil(dj.collection, nil);
  [dj set:@"name" value:@"Shadow"];
  STAssertEquals(counter, (NSUInteger)1, nil);
}

- (void)testRemoveInMultipleCollections {
  NSDictionary *modelData = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithInteger:5], @"id",
                             @"Othello", @"title", nil];
  __block BOOL passed = NO;
  BackboneModel *e = [[BackboneModel alloc] initWithAttributes:modelData];
  BackboneModel *f = [[BackboneModel alloc] initWithAttributes:modelData];
  [f on:@"remove" call:^(NSNotification *notification) {
    passed = YES;
  }];
  BackboneCollection *colE = [[BackboneCollection alloc]
                              initWithModels:[NSArray arrayWithObject:e]];
  BackboneCollection *colF = [[BackboneCollection alloc]
                              initWithModels:[NSArray arrayWithObject:f]];
  STAssertTrue(e != f, nil);
  STAssertEquals(colE.count, (NSUInteger)1, nil);
  STAssertEquals(colF.count, (NSUInteger)1, nil);
  [colE remove:e];
  STAssertFalse(passed, nil);
  STAssertEquals(colE.count, (NSUInteger)0, nil);
  [colF remove:f];
  STAssertEquals(colF.count, (NSUInteger)0, nil);
  STAssertTrue(passed, nil);
}

- (void)removeSameModelInMultipleCollections {
  __block NSUInteger counter = 0;
  
  BackboneCollection *colE = [[BackboneCollection alloc] init];
  BackboneCollection *colF = [[BackboneCollection alloc] init];
  
  BackboneModel *e = [[BackboneModel alloc] initWithAttributes:
                      [NSDictionary dictionaryWithObjectsAndKeys:
                       [NSNumber numberWithInteger:5], @"id",
                       @"Othello", @"title", nil]];
  [e on:@"remove" call:^(NSNotification *notification) {
    BackboneModel *model = [notification.object objectAtIndex:0];
    BackboneCollection *collection = [notification.object objectAtIndex:1];
    
    counter ++;
    
    STAssertEquals(e, model, nil);
    if (counter > 1) {
      STAssertEquals(collection, colF, nil);
    } else {
      STAssertEquals(collection, colE, nil);
    }
  }];
  
  [colE on:@"remove" call:^(NSNotification *notification) {
    BackboneModel *model = [notification.object objectAtIndex:0];
    BackboneCollection *collection = [notification.object objectAtIndex:1];
    
    STAssertEquals(e, model, nil);
    STAssertEquals(colE, collection, nil);
  }];
  
  [colF on:@"remove" call:^(NSNotification *notification) {
    BackboneModel *model = [notification.object objectAtIndex:0];
    BackboneCollection *collection = [notification.object objectAtIndex:1];
    
    STAssertEquals(e, model, nil);
    STAssertEquals(colF, collection, nil);
  }];
  
  STAssertEquals(colE, e.collection, nil);
  [colF remove:e];
  STAssertEquals(colF.count, (NSUInteger)0, nil); 
  STAssertEquals(colE.count, (NSUInteger)1, nil);
  STAssertEquals(counter, (NSUInteger)1, nil);
  STAssertEquals(colE, e.collection, nil);
  [colE remove:e];
  STAssertNil(e.collection, nil);
  STAssertEquals(colE.count, (NSUInteger)0, nil);
  STAssertEquals(counter, (NSUInteger)2, nil);  
}

- (void)testModelDestroyRemovesFromAllCollections {
  MockModel *e = [[MockModel alloc] init];
  
  BackboneCollection *colE = [[BackboneCollection alloc]
                              initWithModels:[NSArray arrayWithObject:e]];
  BackboneCollection *colF = [[BackboneCollection alloc]
                              initWithModels:[NSArray arrayWithObject:e]];
  
  [e destroy];
  STAssertEquals(colE.count, (NSUInteger)0, nil);
  STAssertEquals(colF.count, (NSUInteger)0, nil);
  STAssertNil(e.collection, nil);
}

- (void)testNonPersistedModelDestroyRemovesFromAllCollections {
  MockModel *e = [[MockModel alloc] init];
  
  BackboneCollection *colE = [[BackboneCollection alloc]
                              initWithModels:[NSArray arrayWithObject:e]];
  BackboneCollection *colF = [[BackboneCollection alloc]
                              initWithModels:[NSArray arrayWithObject:e]];
  
  [e destroyWithOptions:0 
        successCallback:^(id model, id response) {
          STAssertTrue(false, @"should not be called");
        } 
          errorCallback:nil];
  
  STAssertEquals(colE.count, (NSUInteger)0, nil);
  STAssertEquals(colF.count, (NSUInteger)0, nil);
  STAssertNil(e.collection, nil);
}

- (void)testFetch {
  [col_ fetch];
  
  NSDictionary *lastRequest = [MockCollection lastRequest];
  STAssertEquals([[lastRequest objectForKey:@"method"] integerValue],
                 BackboneSyncCRUDMethodRead, nil);
  STAssertEquals([lastRequest objectForKey:@"collection"], col_, nil);
}

- (void)testCreate {
  BackboneModel *model =
    [otherCol_ create:[NSDictionary dictionaryWithObject:@"f" forKey:@"label"]
              options:BackboneSyncWait];
  
  NSDictionary *lastRequest = [MockModel lastRequest];
  STAssertEquals([[lastRequest objectForKey:@"method"] integerValue],
                 BackboneSyncCRUDMethodCreate, nil);
  STAssertEquals([lastRequest objectForKey:@"model"], model, nil);
  STAssertEqualObjects([model get:@"label"], @"f", nil);
  STAssertEquals(model.collection, otherCol_, nil);
}

- (void)testCreateEnforcesValidation {
  MockCollection *validationCollection =
    [[MockCollection alloc] initWithModel:[MockModel class] models:nil];
  
  STAssertNil([validationCollection
               create:[NSDictionary
                       dictionaryWithObject:[NSNumber numberWithBool:NO]
                       forKey:@"valid"]]
              , nil);
}

- (void)testAFailingCreateRunsTheErrorCallback {
  MockCollection *validationCollection =
  [[MockCollection alloc] initWithModel:[MockModel class] models:nil];
  
  __block BOOL flag = NO;
  
  [validationCollection
   create:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO]
                                      forKey:@"valid"]
   successCallback:nil           
   errorCallback:^(id model, NSError *error) {
     flag = YES;
   }
   options:0];
  
  STAssertTrue(flag, nil);
}

- (void)testToJSON {
  NSData *data = [NSJSONSerialization
                  dataWithJSONObject:[col_ toJSON] options:0 error:nil];
  STAssertEqualObjects([[NSString alloc] initWithData:data
                                             encoding:NSUTF8StringEncoding],
@"[{\"id\":3,\"label\":\"a\"},{\"id\":2,\"label\":\"b\"},{\"id\":1,\"label\":\"\
c\"},{\"id\":0,\"label\":\"d\"}]",
                       nil);
}

- (void)testWhere {
  BackboneCollection *coll = [[BackboneCollection alloc] initWithModels:
                             [NSArray arrayWithObjects:
                              [NSDictionary dictionaryWithObject:
                               [NSNumber numberWithInteger:1] forKey:@"a"],
                              [NSDictionary dictionaryWithObject:
                               [NSNumber numberWithInteger:1] forKey:@"a"],
                              [NSDictionary dictionaryWithObjectsAndKeys:
                               [NSNumber numberWithInteger:1], @"a",
                               [NSNumber numberWithInteger:2], @"b", nil],
                              [NSDictionary dictionaryWithObjectsAndKeys:
                               [NSNumber numberWithInteger:2], @"a",
                               [NSNumber numberWithInteger:2], @"b", nil],
                              [NSDictionary dictionaryWithObject:
                               [NSNumber numberWithInteger:3] forKey:@"a"],
                              nil]];
  STAssertEquals([coll where:
                  [NSDictionary dictionaryWithObject:
                   [NSNumber numberWithInteger:1] forKey:@"a"]].count,
                 (NSUInteger)3, nil);
  STAssertEquals([coll where:
                  [NSDictionary dictionaryWithObject:
                   [NSNumber numberWithInteger:2] forKey:@"a"]].count,
                 (NSUInteger)1, nil);
  STAssertEquals([coll where:
                  [NSDictionary dictionaryWithObject:
                   [NSNumber numberWithInteger:3] forKey:@"a"]].count,
                 (NSUInteger)1, nil);
  STAssertEquals([coll where:
                  [NSDictionary dictionaryWithObject:
                   [NSNumber numberWithInteger:1] forKey:@"b"]].count,
                 (NSUInteger)0, nil);
  STAssertEquals([coll where:
                  [NSDictionary dictionaryWithObject:
                   [NSNumber numberWithInteger:2] forKey:@"b"]].count,
                 (NSUInteger)2, nil);
  NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                         [NSNumber numberWithInteger:1], @"a",
                         [NSNumber numberWithInteger:2], @"b", nil];
  STAssertEquals([coll where:attrs].count, (NSUInteger)1, nil);
}

- (void)testReset {
  __block NSUInteger resetCount = 0;
  NSArray *models = col_.models;
  [col_ on:@"reset" call:^(NSNotification *notification) {
    resetCount ++;
  }];
  [col_ reset:[NSArray array]];
  STAssertEquals(resetCount, (NSUInteger)1, nil);
  STAssertEquals(col_.count, (NSUInteger)0, nil);
  STAssertNil([col_ lastObject], nil);
  [col_ reset:models];
  STAssertEquals(resetCount, (NSUInteger)2, nil);
  STAssertEquals(col_.count, (NSUInteger)4, nil);
  STAssertEquals([col_ lastObject], d_, nil);
  
  NSMutableArray *modelAttributes = [NSMutableArray array];
  for (BackboneModel *model in models) {
    [modelAttributes addObject:model.attributes];
  }
  [col_ reset:modelAttributes];
  
  STAssertEquals(resetCount, (NSUInteger)3, nil);
  STAssertEquals(col_.count, (NSUInteger)4, nil);
  STAssertTrue([col_ lastObject] != d_, nil);
  STAssertEqualObjects([[col_ lastObject] attributes], d_.attributes, nil);
}

- (void)testTriggerCustomEventsOnModel {
  __block BOOL fired = NO;
  [a_ on:@"custom" call:^(NSNotification *notification) {
    fired = YES;
  }];
  [a_ trigger:@"custom"];
  STAssertTrue(fired, nil);
}

- (void)testAddDoesNotAlterArguments {
  NSDictionary *attrs = [NSDictionary dictionary];
  NSArray *models = [NSArray arrayWithObject:attrs];
  BackboneCollection *collection =
    [[BackboneCollection alloc] initWithModels:models];
  STAssertEquals(collection.count, (NSUInteger)1, nil);
  STAssertEquals(models.count, (NSUInteger)1, nil);
  STAssertEquals(attrs, [models objectAtIndex:0], nil);
}

- (void)testRemovingItsOwnReferenceToTheModelsArray {
  BackboneCollection *col = [[BackboneCollection alloc] initWithModels:
                             [NSArray arrayWithObjects:
                              [NSDictionary dictionaryWithObject:@"1"
                                                          forKey:@"id"],
                              [NSDictionary dictionaryWithObject:@"2"
                                                          forKey:@"id"],
                              [NSDictionary dictionaryWithObject:@"3"
                                                          forKey:@"id"],
                              [NSDictionary dictionaryWithObject:@"4"
                                                          forKey:@"id"],
                              [NSDictionary dictionaryWithObject:@"5"
                                                          forKey:@"id"],
                              [NSDictionary dictionaryWithObject:@"6"
                                                          forKey:@"id"],
                              nil]];
  STAssertEquals(col.count, (NSUInteger)6, nil);
  [col removeModels:col.models];
  STAssertEquals(col.count, (NSUInteger)0, nil);
}

- (void)testAddingModelsToACollectionWhichDoNotPassValidation {
  BackboneCollection *col =
    [[BackboneCollection alloc] initWithModel:[MockModel class] models:nil];
  NSArray *models = [NSArray arrayWithObjects:
                     [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:NO], @"valid",
                      [NSNumber numberWithInteger:1], @"id",
                      nil],
                     [NSDictionary dictionaryWithObject:
                      [NSNumber numberWithInteger:2] forKey:@"id"],
                     [NSDictionary dictionaryWithObject:
                      [NSNumber numberWithInteger:3] forKey:@"id"],
                     [NSDictionary dictionaryWithObject:
                      [NSNumber numberWithInteger:4] forKey:@"id"],
                     [NSDictionary dictionaryWithObject:
                      [NSNumber numberWithInteger:5] forKey:@"id"],
                     [NSDictionary dictionaryWithObject:
                      [NSNumber numberWithInteger:6] forKey:@"id"],
                     nil];
  STAssertThrows([col addModels:models], nil);
}

- (void)testIndexWithComparator {
  __block NSUInteger counter = 0;
  BackboneCollection *col = [[BackboneCollection alloc] initWithModels:
                             [NSArray arrayWithObjects:
                              [NSDictionary dictionaryWithObject:@"2"
                                                          forKey:@"id"],
                              [NSDictionary dictionaryWithObject:@"4"
                                                          forKey:@"id"],
                              nil]];
  col.comparator = ^(id a, id b) {
    return [[a id] compare:[b id]];
  };
  [col on:@"add" call:^(NSNotification *notification) {
    BackboneModel *model = [notification.object objectAtIndex:0];
    NSUInteger index =
      [[notification.object objectAtIndex:3] integerValue];
    if ([model.id integerValue] == 1) {
      STAssertEquals(index, (NSUInteger)0, nil);
      STAssertEquals(counter++, (NSUInteger)0, nil);
    }
    if ([model.id integerValue] == 3) {
      STAssertEquals(index, (NSUInteger)2, nil);
      STAssertEquals(counter++, (NSUInteger)1, nil);      
    }
  }];
  [col addModels:[NSArray arrayWithObjects:
                  [NSDictionary dictionaryWithObject:@"3"
                                              forKey:@"id"],
                  [NSDictionary dictionaryWithObject:@"1"
                                              forKey:@"id"],
                  nil]];
}

- (void)testThrowingDuringAddLeavesConsistentState {
  BackboneCollection *col =
    [[BackboneCollection alloc] initWithModel:[MockModel class] models:nil];
  [col on:@"test" call:^(NSNotification *notification) {
    STAssertTrue(false, nil);
  }];
  MockModel *model = [[MockModel alloc] initWithAttributes:
                      [NSDictionary dictionaryWithObjectsAndKeys:
                       [NSNumber numberWithInteger:1], @"id",
                       [NSNumber numberWithBool:YES], @"valid", nil]];
  NSArray *models = [NSArray arrayWithObjects:
                     model,
                     [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithInteger:2], @"id",
                      [NSNumber numberWithBool:NO], @"valid", nil],
                     nil];
  STAssertThrows([col addModels:models], nil);
  STAssertNil([col getByCid:model.cid], nil);
  STAssertNil([col get:[NSNumber numberWithInteger:1]], nil);
  STAssertEquals(col.count, (NSUInteger)0, nil);
}

- (void)testMultipleCopiesOfTheSameModel {
  BackboneCollection *col = [[BackboneCollection alloc] init];
  BackboneModel *model = [[BackboneModel alloc] init];
  [col addModels:[NSArray arrayWithObjects:model, model, nil]];
  STAssertEquals(col.count, (NSUInteger)1, nil);
  [col addModels:[NSArray arrayWithObjects:
                  [NSDictionary dictionaryWithObject:@"1"
                                              forKey:@"id"],
                  [NSDictionary dictionaryWithObject:@"1"
                                              forKey:@"id"], nil]];
  STAssertEquals(col.count, (NSUInteger)2, nil);
  STAssertEquals([[[col lastObject] id] integerValue], 1, nil);
}

@end
