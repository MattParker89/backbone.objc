//
//  NSObject+Backbone.m
//  Backbone
//
//  Created by Edmond Leung on 7/21/12.
//  Copyright (c) 2012. All rights reserved.
//

#import "NSObject+Backbone.h"

@implementation NSObject (Backbone)

- (id)performSelector:(SEL)selector withObjects:(NSArray *)objects {
  NSMethodSignature *signature;
  NSInvocation *invocation;
  NSUInteger index;
  id returnValue;
  
  if (!(signature = [self methodSignatureForSelector:selector])) return nil;
  
  invocation = [NSInvocation invocationWithMethodSignature:signature];
  [invocation setTarget:self];
  [invocation setSelector:selector];
  
  index = 2;
  for (__strong id object in objects) {
    [invocation setArgument:&object atIndex:index ++];  
  }
  
  [invocation invoke];
  
  if (signature.methodReturnLength) {
    [invocation getReturnValue:&returnValue];
    return returnValue;;
  }
  
  return nil;
}

@end
