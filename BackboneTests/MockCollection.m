//
//  MockCollection.m
//  Backbone
//
//  Created by Edmond Leung on 7/12/12.
//  Copyright (c) 2012. All rights reserved.
//

#import "MockCollection.h"

static NSDictionary *lastRequest__;

@implementation MockCollection

+ (void)sync:(BackboneCollection *)collection
      method:(BackboneSyncCRUDMethod)method
successCallback:(BackboneSyncSuccessBlock)successCallback
errorCallback:(BackboneErrorBlock)errorCallback {
  lastRequest__ = [NSDictionary dictionaryWithObjectsAndKeys:
                   [NSNumber numberWithInteger:method], @"method",
                   collection, @"collection",
                   errorCallback, @"error", nil];
  
  if (successCallback) successCallback(collection, nil);
}

+ (NSDictionary *)lastRequest {
  return lastRequest__;
}

+ (void)clearLastRequest {
  lastRequest__ = nil;
}

@end
