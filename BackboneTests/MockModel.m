//
//  MockModel.m
//  Backbone
//
//  Created by Edmond Leung on 5/27/12.
//  Copyright (c) 2012. All rights reserved.
//

#import "MockModel.h"

static NSDictionary *lastRequest__;

@implementation MockModel

@synthesize validated = validated_;
@dynamic one;

+ (void)sync:(BackboneModel *)model
      method:(BackboneSyncCRUDMethod)method
successCallback:(BackboneSyncSuccessBlock)successCallback
errorCallback:(BackboneErrorBlock)errorCallback {
  lastRequest__ = [NSDictionary dictionaryWithObjectsAndKeys:
                   [NSNumber numberWithInteger:method], @"method",
                   model, @"model",
                   errorCallback, @"error", nil];
  
  if (successCallback) successCallback(model, nil);
}

+ (NSDictionary *)lastRequest {
  return lastRequest__;
}

+ (void)clearLastRequest {
  lastRequest__ = nil;
}

+ (NSString *)idAttribute {
  return @"_id";
}

+ (NSDictionary *)defaults {
  return [NSDictionary dictionaryWithObjectsAndKeys:
          [NSNumber numberWithInteger:1], @"one",
          [NSNumber numberWithInteger:2], @"two",
          [NSNumber numberWithBool:YES], @"valid",
          nil];
}

- (NSError *)validate:(NSDictionary *)attributes {
  id valid = [attributes objectForKey:@"valid"];
  
  validated_ = YES;
  
  if ([valid isEqual:[NSNull null]] || ![valid boolValue]) {
    return [NSError errorWithDomain:@"com.backbone" code:0 userInfo:
            [NSDictionary dictionaryWithObject:@"Invalid" forKey:@"valid"]];
  }
  
  return nil;
}

- (NSDictionary *)parse:(NSDictionary *)response {
  NSNumber *value;
  
  NSMutableDictionary *parsedResponse =
    [NSMutableDictionary dictionaryWithDictionary:response];
  
  if ((value = [parsedResponse objectForKey:@"value"])) {
    [parsedResponse
     setValue:[NSNumber numberWithInteger:[value integerValue] + 1]
     forKey:@"value"];
  }
  
  return parsedResponse;
}

@end
