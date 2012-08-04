//
//  BackboneRouter.m
//  Backbone
//
//  Created by Edmond Leung on 7/20/12.
//  Copyright (c) 2012. All rights reserved.
//

#import "BackboneRouter.h"
#import "ARCHelper.h"
#import "Mixin.h"
#import "NSObject+Backbone.h"
#import "Backbone.h"

@implementation BackboneRouter

static const NSString *namedParam = @":\\w+";
static const NSString *splatParam = @"\\*\\w+";
static const NSString *escapeRegExp = @"[-\\[\\]{}()+?.,\\\\^$|#\\s]";

+ (void)initialize {
	if ([self class] == [BackboneRouter class]) {
    // Mixin BackboneEvents methods into BackboneRouter.
		[Mixin from:[BackboneEvents class] into:self];
  }
}

- (void)route:(id)route name:(NSString *)name {
  [self route:route name:name selector:NSSelectorFromString(name)];
}

- (void)route:(id)route name:(NSString *)name selector:(SEL)selector {
  if ([route isKindOfClass:[NSString class]]) {
    route = [self routeToRegExp:route];
  }
  
  [[Backbone history] route:route toCallback:^(NSString *url) {
    NSArray *args;
    NSString *eventName;
    
    args = [self extractParameters:route url:url];
    eventName = [NSString stringWithFormat:@"route:%@", name];
    
    if ([self respondsToSelector:selector]) {
      [self performSelector:selector withObjects:args];
    }
    
    [self trigger:eventName argumentsArray:args];
    [[Backbone history] trigger:@"route" arguments:self, name, args, nil];
  }];
}

- (void)navigate:(NSString *)url options:(BackboneHistoryOptions)options {
  [[Backbone history] navigate:url options:options];
}

- (NSRegularExpression *)routeToRegExp:(NSString *)route {
  NSMutableString *pattern;
  NSArray *conversions;
  NSString *routePattern;
  NSRegularExpression *regExp;
  NSUInteger index;
  
  pattern = [NSMutableString stringWithString:route];
  conversions = [NSArray arrayWithObjects:
                 escapeRegExp, @"\\\\$0",
                 namedParam, @"([^\\/]+)",
                 splatParam, @"(.*?)", nil];
  
  for (index = 0; index < conversions.count; index ++) {
    routePattern = [conversions objectAtIndex:index];
    
    regExp = [NSRegularExpression regularExpressionWithPattern:routePattern
                                                       options:0
                                                         error:nil];
    [regExp replaceMatchesInString:pattern
                           options:NSRegularExpressionSearch
                             range:NSMakeRange(0, pattern.length)
                      withTemplate:[conversions objectAtIndex:++index]];
  }
  
  [pattern insertString:@"^" atIndex:0];
  [pattern appendString:@"$"];
  
  return [NSRegularExpression regularExpressionWithPattern:pattern
                                                   options:0
                                                     error:nil];
}

- (NSArray *)extractParameters:(NSRegularExpression *)route
                           url:(NSString *)url {
  NSTextCheckingResult *result;
  NSMutableArray *parameters;
  NSUInteger index;
  
  result = [route firstMatchInString:url
                             options:NSRegularExpressionSearch
                               range:NSMakeRange(0, [url length])];
  
  parameters = [NSMutableArray array];
  
  for (index = 1; index < result.numberOfRanges; index ++) {
    [parameters addObject:[url substringWithRange:[result rangeAtIndex:index]]];
  }
  
  return [NSArray arrayWithArray:parameters];
}

@end