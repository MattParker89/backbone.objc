//
//  BackboneEvents.h
//  Backbone
//
//  Created by Edmond Leung on 5/11/12.
//  Copyright (c) 2012. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BackboneTypes.h"

@protocol BackboneEventsMixin <NSObject>

@optional

- (void)on:(NSString *)events call:(BackboneEventBlock)callback;
- (void)on:(NSString *)events
      call:(BackboneEventBlock)callback
  observer:(id)observer;

- (void)bind:(NSString *)events to:(BackboneEventBlock)callback;
- (void)bind:(NSString *)events
          to:(BackboneEventBlock)callback
    observer:(id)observer;

- (void)off;
- (void)off:(id)eventsOrCallback;
- (void)off:(NSString *)events call:(BackboneEventBlock)callback;
- (void)off:(NSString *)events observer:(id)observer;

- (void)unbind;
- (void)unbind:(id)eventsOrCallback;
- (void)unbind:(NSString *)events from:(BackboneEventBlock)callback;
- (void)unbind:(NSString *)events observer:(id)observer;

- (void)trigger:(NSString *)events;
- (void)trigger:(NSString *)events argumentsArray:(NSMutableArray *)arguments;
- (void)trigger:(NSString *)events 
      arguments:(id)firstArgument, ... NS_REQUIRES_NIL_TERMINATION;

@end

@interface BackboneEvents : NSObject<BackboneEventsMixin>

@end
