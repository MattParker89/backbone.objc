//
//  BackboneEventsTests.m
//  BackboneTests
//
//  Created by Edmond Leung on 5/11/12.
//  Copyright (c) 2012. All rights reserved.
//

#import "BackboneEventsTests.h"
#import "BackboneEvents.h"

@implementation BackboneEventsTests

- (void)testOnAndTrigger {
  __block NSInteger counter = 0;
  BackboneEvents *events = [[BackboneEvents alloc] init];
  
  [events on:@"event" call:^(NSNotification *notification) { 
    counter++;
  }];
  [events trigger:@"event"];
  
  STAssertEquals(counter, 1, @"counter should be incremented.");

  [events trigger:@"event"];
  [events trigger:@"event"];
  [events trigger:@"event"];
  [events trigger:@"event"];
  
  STAssertEquals(counter, 5, 
                 @"counter should be incremented five times.");
}

- (void)testBindingAndTriggeringOfMultipleEvents {
  __block NSInteger counter = 0;
  BackboneEvents *events = [[BackboneEvents alloc] init];
  
  [events on:@"a b c" call:^(NSNotification *notification) {
    counter++;
  }];
  
  [events trigger:@"a"];
  STAssertEquals(counter, 1, nil);
  
  [events trigger:@"a b"];
  STAssertEquals(counter, 3, nil);
  
  [events trigger:@"c"];
  STAssertEquals(counter, 4, nil);
  
  [events off:@"a c"];
  [events trigger:@"a b c"];
  STAssertEquals(counter, 5, nil);
}

- (void)testTriggeringAllForEachEvent {
  __block NSNumber *a, *b;
  __block NSInteger counter = 0;
  BackboneEvents *events = [[BackboneEvents alloc] init];
  
  [events on:@"all" call:^(NSNotification *notification) {
    NSString *event = notification.name;
    counter++;
    if ([event isEqualToString:@"a"]) a = [NSNumber numberWithBool:YES];
    if ([event isEqualToString:@"b"]) b = [NSNumber numberWithBool:YES];
  }];
  
  [events trigger:@"a b"];
  
  STAssertNotNil(a, nil);
  STAssertNotNil(b, nil);
  STAssertEquals(counter, 2, nil);
}

- (void)testOnThenUnbindingAllBlocks {
  __block NSInteger counter = 0;
  BackboneEvents *events = [[BackboneEvents alloc] init];
  
  [events on:@"event" call:^(NSNotification *notification) {
    counter++;
  }];
  [events trigger:@"event"];
  [events off:@"event"];
  [events trigger:@"event"];
  
  STAssertEquals(counter, 1, 
                 @"counter should have only been incremented once.");
}

- (void)testBindingOfTwoCallbacksAndUnbindingOnlyOne {
  __block NSInteger counterA, counterB;
  BackboneEvents *events = [[BackboneEvents alloc] init];
  counterA = 0;
  counterB = 0;
  
  void (^callback)(NSNotification *) = ^(NSNotification *notification) {
    counterA++;
  };
  
  [events on:@"event" call:callback];
  [events on:@"event" call:^(NSNotification *notification) {
    counterB++;
  }];
  
  [events trigger:@"event"];
  [events off:@"event" call:callback]; 
  [events trigger:@"event"];
  
  STAssertEquals(counterA, 1, 
                 @"counterA should have only been incremented once.");
  STAssertEquals(counterB, 2, 
                 @"counterB should have been incremented twice.");
}

- (void)testUnbindingOfACallbackInTheMidstOfItFiring {
  __block NSInteger counter = 0;
  BackboneEvents *events = [[BackboneEvents alloc] init];
  
  __block id callback = ^(NSNotification *notification) {
    counter++;
    [events unbind:@"event" from:callback];
  };
  
  [events bind:@"event" to:callback];
  [events trigger:@"event"];
  [events trigger:@"event"];
  [events trigger:@"event"];
  
  STAssertEquals(counter, 1, 
                 @"the callback should have been unbound.");
}

- (void)testTwoBindsThatUnbindsThemselves {
  __block NSInteger counterA, counterB;
  BackboneEvents *events = [[BackboneEvents alloc] init];
  counterA = 0;
  counterB = 0;
  
  __block id incrA = ^(NSNotification *notification) {
    counterA++;
    [events unbind:@"event" from:incrA];
  };
  
  __block id incrB = ^(NSNotification *notification) {
    counterB++;
    [events unbind:@"event" from:incrB];
  };
  
  [events bind:@"event" to:incrA];
  [events bind:@"event" to:incrB];
  
  [events trigger:@"event"];
  [events trigger:@"event"];
  [events trigger:@"event"];
  
  STAssertEquals(counterA, 1, 
                 @"counterA should have only been incremented once.");
  STAssertEquals(counterB, 1, 
                 @"counterB should have only been incremented once.");
}

- (void)testNestedTriggeringWithUnbind {
  __block NSInteger counter = 0;
  BackboneEvents *events = [[BackboneEvents alloc] init];
  
  __block id incr1 = ^(NSNotification *notification) {
    counter++;
    [events unbind:@"event" from:incr1];
    [events trigger:@"event"];
  };
  
  __block id incr2 = ^(NSNotification *notification) {
    counter++;
  };
  
  [events bind:@"event" to:incr1];
  [events bind:@"event" to:incr2];
  [events trigger:@"event"];
  
  STAssertEquals(counter, 3, 
                 @"counter should have been incremented three times.");
}

- (void)testCallbackListIsNotAlteredDuringTrigger {
  __block NSInteger counter = 0;
  BackboneEvents *events = [[BackboneEvents alloc] init];
  
  __block id incr = ^(NSNotification *notification) {
    counter++;
  };
  
  [events bind:@"event" to:^(NSNotification *notification) {
    [events bind:@"event" to:incr];
    [events bind:@"all" to:incr];
  }];
  [events trigger:@"event"];
  
  STAssertEquals(counter, 0, 
                 @"bind does not alter callback list.");
  
  [events unbind];
  [events bind:@"event" to:^(NSNotification *notification) {
    [events unbind:@"event" from:incr];
    [events unbind:@"all" from:incr];
  }];
  [events bind:@"event" to:incr];
  [events bind:@"all" to:incr];
  [events trigger:@"event"];

  STAssertEquals(counter, 2, 
                 @"unbind does not alter callback list.");
}

- (void)testAllCallbackListIsRetrievedAfterEachEvent {
  __block NSInteger counter = 0;
  BackboneEvents *events = [[BackboneEvents alloc] init];

  __block id incr = ^(NSNotification *notification) {
    counter++;
  };
  
  [events on:@"x" call:^(NSNotification *notification) {
    [events on:@"y" call:incr];
    [events on:@"all" call:incr];
  }];
  
  [events trigger:@"x y"];

  STAssertEquals(counter, 2, nil);
  
  [events off:@"y" call:incr];
  [events off:@"all" call:incr];
  
}

- (void)testIfNoCallbackIsProvidedThenOnIsANoop {
  BackboneEvents *events = [[BackboneEvents alloc] init];
  [events bind:@"test" to:nil];
  [events trigger:@"test"];
}

- (void)testRemoveEventsForASpecificContext {
  BackboneEvents *events = [[BackboneEvents alloc] init];
  
  [events on:@"x y all" call:^(NSNotification *notification) {
    STAssertTrue(true, nil);
  }];
  [events on:@"x y all" call:^(NSNotification *notification) {
    STAssertTrue(false, nil);
  } observer:self];
  
  [events off:nil observer:self];
  [events trigger:@"x y"];
}

- (void)testRemovingOfAllEventsForASpecificCallback {
  BackboneEvents *events = [[BackboneEvents alloc] init];
  
  __block id success = ^(NSNotification *notification) {
    STAssertTrue(true, nil);
  };
  __block id fail = ^(NSNotification *notification) {
    STAssertTrue(false, nil);
  };
  
  [events on:@"x y all" call:success];
  [events on:@"x y all" call:fail];
  [events off:nil call:fail];
  [events trigger:@"x y"];
}

@end
