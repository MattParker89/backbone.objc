//
//  NSArray+Backbone.m
//  Backbone
//
//  Created by Edmond Leung on 5/28/12.
//  Copyright (c) 2012. All rights reserved.
//

#import "NSArray+Backbone.h"
#import "NSString+Backbone.h"

@implementation NSArray (Backbone)

- (NSString *)encodedURLWithPrefix:(NSString *)prefix {
  NSMutableArray *components;
  NSUInteger index;
  id value;
  NSString *nextPrefix;
  
  components = [NSMutableArray array];
  
  for (index = 0; index < self.count; index++) {
    value = [self objectAtIndex:index];
    nextPrefix = [NSString stringWithFormat:@"%@[%u]", prefix, index];
    
    if ([value isKindOfClass:[NSDictionary class]] || 
        [value isKindOfClass:[NSArray class]]) {
      [components addObject:[value encodedURLWithPrefix:nextPrefix]];
    } else {
      [components addObject:
       [NSString stringWithFormat:@"%@[]=%@",
        prefix, [value encodedURL]]];
    }
  }
  
  return [components componentsJoinedByString:@"&"];
}

- (NSString *)encodedURL {
  return [self encodedURLWithPrefix:nil];
}

- (NSDictionary *)toJSON {
  NSMutableArray *result = [NSMutableArray array];
  
  for (__strong id object in self) {
    if ([object respondsToSelector:@selector(toJSON)]) {
      object = [object performSelector:@selector(toJSON)];
    }
    [result addObject:object];
  }
  
  return [NSArray arrayWithArray:result];
}

@end
