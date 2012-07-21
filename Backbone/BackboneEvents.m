//
//  BackboneEvents.m
//  Backbone
//
//  Created by Edmond Leung on 5/11/12.
//  Copyright (c) 2012. All rights reserved.
//

#import "BackboneEvents.h"
#import "ARCHelper.h"

#define VarArgs(_last_) ({ \
  NSMutableArray *__args = [NSMutableArray array]; \
  if (_last_) { \
    [__args addObject:_last_]; \
    id obj; \
    va_list ap; \
    va_start(ap, _last_); \
    while ((obj = va_arg(ap, id))) { \
      [__args addObject:obj]; \
    } \
    va_end(ap); \
  } \
  __args; })

@implementation BackboneEvents

static NSMutableDictionary *caches__ = nil;

+ (NSValue *)cacheIdentifierFor:(id)object {
  return [NSValue valueWithNonretainedObject:object];
}

- (void)on:(NSString *)events call:(BackboneEventBlock)callback {
  [self on:events call:callback observer:nil];
}

- (void)on:(NSString *)events
      call:(BackboneEventBlock)callback
  observer:(id)observer {
  NSValue *observerCacheIdentifier, *eventCacheIdentifier;
  NSMutableDictionary *observerCache, *eventCache;
  NSArray *eventsAsArray;
  NSMutableArray *list;
  
  if (!callback) return;
  
  if (!observer) observer = [NSNull null];
  
  observerCacheIdentifier = [[self class] cacheIdentifierFor:self];
  eventCacheIdentifier = [[self class] cacheIdentifierFor:observer];
  
  // Create caches if they don't exist yet.
  if (!caches__) caches__ = [[NSMutableDictionary alloc] init];
  if (!(observerCache = [caches__ objectForKey:observerCacheIdentifier])) {
    [caches__ setObject:(observerCache = [NSMutableDictionary dictionary]) 
                 forKey:observerCacheIdentifier];
  }
  if (!(eventCache = [observerCache objectForKey:eventCacheIdentifier])) {
    [observerCache setObject:(eventCache = [NSMutableDictionary dictionary]) 
                      forKey:eventCacheIdentifier];
  }
  
  eventsAsArray = [events componentsSeparatedByCharactersInSet:
                   [NSCharacterSet whitespaceAndNewlineCharacterSet]];
  
  // Loop through and add callbacks where appropriate.
  for (NSString *event in eventsAsArray) {
    if (!(list = [eventCache objectForKey:event])) {
      [eventCache setObject:(list = [NSMutableArray array]) forKey:event];
    }
    
    [list addObject:AH_BLOCK_COPY(callback)];
  }
}

- (void)bind:(NSString *)events to:(BackboneEventBlock)callback {
  [self bind:events to:callback observer:nil];
}

- (void)bind:(NSString *)events
          to:(BackboneEventBlock)callback
    observer:(id)observer {
  [self on:events call:callback observer:observer];
}

- (void)off {
  if (caches__) [self off:nil call:nil observer:nil];
}

- (void)off:(id)eventsOrCallback {
  if ([eventsOrCallback isKindOfClass:[NSString class]]) {
    [self off:eventsOrCallback call:nil];
  } else {    
    [self off:nil call:eventsOrCallback];
  }
}

- (void)off:(NSString *)events call:(BackboneEventBlock)callback {
  [self off:events call:callback observer:nil];
}

- (void)off:(NSString *)events observer:(id)observer {
  [self off:events call:nil observer:observer];
}

- (void)off:(NSString *)events
       call:(BackboneEventBlock)callback
   observer:(id)observer {
  NSValue *observerCacheIdentifier, *eventCacheIdentifier;
  NSMutableDictionary *observerCache, *eventCache;
  NSArray *cachedEventsAsArray, *eventsAsArray, *eventCacheIdentifiers;
  NSMutableArray *list;
  
  observerCacheIdentifier = [[self class] cacheIdentifierFor:self];
  eventCacheIdentifier = [[self class] cacheIdentifierFor:observer];
  
  if (caches__ && 
      (observerCache = [caches__ objectForKey:observerCacheIdentifier])) {    
    if (events) {
      cachedEventsAsArray = [events componentsSeparatedByCharactersInSet:
                             [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    } else {
      cachedEventsAsArray = nil;
    }
    
    if (!observer) {
      eventCacheIdentifiers = observerCache.allKeys;
    } else {
      eventCacheIdentifiers = 
        [NSArray arrayWithObject:[[self class] cacheIdentifierFor:observer]];
    }
    
    for (eventCacheIdentifier in eventCacheIdentifiers) {
      if ((eventCache = [observerCache objectForKey:eventCacheIdentifier])) {
        if (cachedEventsAsArray) {
          eventsAsArray = cachedEventsAsArray;
        } else {
          eventsAsArray = eventCache.allKeys;
        }
        
        // Loop through and removing callbacks where appropriate.
        for (NSString *event in eventsAsArray) {
          if ((list = [eventCache objectForKey:event])) {
            if (callback) {
              AH_BLOCK_RELEASE(callback);
              [list removeObject:callback];
            } else {
              for (callback in list) AH_BLOCK_RELEASE(callback);
              [eventCache removeObjectForKey:event];
            }
          }
        }
      }
      
      // Remove the caches if they don't have any content anymore.
      if (eventCache.allKeys.count == 0) {
        [observerCache removeObjectForKey:eventCacheIdentifier];
      }
    }
    
    if (observerCache.allKeys.count == 0) {
      [caches__ removeObjectForKey:observerCacheIdentifier];
    }
  }
}

- (void)unbind {
  [self off];
}

- (void)unbind:(id)eventsOrCallback {
  [self off:eventsOrCallback];
}

- (void)unbind:(NSString *)events from:(BackboneEventBlock)callback {
  [self off:events call:callback];
}

- (void)unbind:(NSString *)events observer:(id)observer {
  [self off:events call:nil observer:observer];
}

- (void)trigger:(NSString *)events {
  [self trigger:events argumentsArray:nil];
}

- (void)trigger:(NSString *)events argumentsArray:(NSArray *)arguments {
  NSArray *eventsAsArray, *all;
  NSMutableArray *list;
  NSNotification *notification;
  NSValue *eventCacheIdentifier;
  NSMutableDictionary *observerCache, *eventCache;
  
  if (caches__) {
    observerCache =
      [caches__ objectForKey:[[self class] cacheIdentifierFor:self]];
    
    if (!arguments) arguments = [NSArray array];
    
    eventsAsArray = [events componentsSeparatedByCharactersInSet:
                     [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    // For each event, walk through the list of callbacks twice, first to
    // trigger the event, then to trigger any "all" callbacks.
    for (NSString *event in eventsAsArray) {
      notification = [NSNotification notificationWithName:event 
                                                   object:arguments];
      
      for (eventCacheIdentifier in observerCache) {
        eventCache = [observerCache objectForKey:eventCacheIdentifier];
        
        // Copy callback lists to prevent modification.
        if ((all = [eventCache objectForKey:@"all"])) {
          all = [NSArray arrayWithArray:all];
        }
        
        // Execute event callbacks.
        if ((list = [eventCache objectForKey:event])) {
          list = [NSArray arrayWithArray:list];
          for (void (^callback)(NSNotification *) in list) {
            callback(notification);
          }
        }
        
        // Execute "all" callbacks.
        if (all) {
          for (void (^callback)(NSNotification *) in all) {
            callback(notification);
          }
        }
      }
    }
  }
}

- (void)trigger:(NSString *)events 
      arguments:(id)firstArgument, ... NS_REQUIRES_NIL_TERMINATION {
  [self trigger:events argumentsArray:VarArgs(firstArgument)];
}

@end
