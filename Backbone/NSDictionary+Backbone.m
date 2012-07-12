//
//  NSDictionary+Backbone.m
//  Backbone
//
//  Created by Edmond Leung on 5/26/12.
//  Copyright (c) 2012. All rights reserved.
//

#import "NSDictionary+Backbone.h"
#import "NSString+Backbone.h"

@implementation NSDictionary (Backbone)

- (NSDictionary *)extend:(NSDictionary *)dictionary {
  NSMutableDictionary *extendedDictionary;
  id key;
  
  extendedDictionary = [NSMutableDictionary dictionaryWithDictionary:self];
  for (key in dictionary) {
    [extendedDictionary setObject:[dictionary objectForKey:key] forKey:key];
  }
  
  return extendedDictionary;
}

- (NSString *)encodedURLWithPrefix:(NSString *)prefix {
  NSMutableArray *components;
  NSString *key;
  id value;
  
  components = [NSMutableArray array];
  
  for (key in self) {
    value = [self objectForKey:key];
    key = [key encodedURL];
    if (prefix) key = [NSString stringWithFormat:@"%@[%@]", prefix, key];
    
    if ([value isKindOfClass:[NSDictionary class]] || 
        [value isKindOfClass:[NSArray class]]) {
      [components addObject:[value encodedURLWithPrefix:key]];
    } else {
      value = [[NSString stringWithFormat:@"%@", value] encodedURL];
      [components addObject:[NSString stringWithFormat:@"%@=%@", key, value]];
    }
  }
  
  return [components componentsJoinedByString:@"&"];
}

- (NSString *)encodedURL {
  return [self encodedURLWithPrefix:nil];
}

- (NSDictionary *)toJSON {
  NSMutableDictionary *result = [NSMutableDictionary dictionary];
  
  for (id key in self) {
    id object = [self objectForKey:key];
    if ([object respondsToSelector:@selector(toJSON)]) {
      object = [object performSelector:@selector(toJSON)];
    }
    [result setObject:object forKey:key];
  }
  
  return [NSDictionary dictionaryWithDictionary:result];
}

@end
