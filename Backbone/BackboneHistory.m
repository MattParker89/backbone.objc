//
//  BackboneHistory.m
//  Backbone
//
//  Created by Edmond Leung on 7/19/12.
//  Copyright (c) 2012. All rights reserved.
//

#import "BackboneHistory.h"
#import "ARCHelper.h"
#import "Mixin.h"
#import "Backbone.h"

@implementation BackboneHistory

+ (void)initialize {
  if ([self class] == [BackboneHistory class]) {
    // Mixin BackboneEvents methods into BackboneCollection.
    [Mixin from:[BackboneEvents class] into:self];
  }
}

- (id)init {
  self = [super init];
  
  if (self) {
    handlers_ = AH_RETAIN([NSMutableArray array]);
    history_ = AH_RETAIN([NSMutableArray array]);
  }
  
  return self;
}

- (void)route:(NSRegularExpression *)route
   toCallback:(void (^)(NSString *url))callback {
  [handlers_ insertObject:@{@"route": route,
                           @"callback": AH_BLOCK_COPY(callback)}
                  atIndex:0];
}

- (BOOL)loadUrl:(NSString *)url {
  NSDictionary *handler;
  NSRegularExpression *route;
  void (^callback)(NSString *url);
  
  for (handler in handlers_) {
    route = [handler objectForKey:@"route"];
    callback = [handler objectForKey:@"callback"];
    
    if ([route numberOfMatchesInString:url
                               options:0
                                 range:NSMakeRange(0, url.length)] > 0) {
      callback([url stringByReplacingPercentEscapesUsingEncoding:
                NSUTF8StringEncoding]);
      return YES;
    }
  }
  
  return NO;
}

- (void)navigate:(NSString *)url options:(BackboneHistoryOptions)options {
  if ([[history_ lastObject] isEqualToString:url]) return;
  
  // Replace the current url in the history log.
  if (options & BackboneHistoryReplace) [history_ removeLastObject];
  
  [history_ addObject:url];
  
  // Fire the route callback.
  if (options & BackboneHistoryTrigger) [self loadUrl:url];
}

- (void)dealloc {  
  AH_RELEASE(handlers_);
  AH_RELEASE(history_);

  // Remove all events binded to history.
  [self off];
  
  AH_SUPER_DEALLOC;
}

@end
