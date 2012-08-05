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
    const char *type =
      [[[self class] instanceMethodSignatureForSelector:selector]
       getArgumentTypeAtIndex:index];
    
    if (strcmp(type, @encode(unsigned int)) == 0) {
      unsigned int argument = [object intValue];
      [invocation setArgument:&argument atIndex:index];
    } else if (strcmp(type,@encode(int)) == 0) {
      int argument = [object intValue];
      [invocation setArgument:&argument atIndex:index];
    } else if (strcmp(type, @encode(unsigned short)) == 0) {
      unsigned short argument = [object shortValue];
      [invocation setArgument:&argument atIndex:index];
    } else if (strcmp(type,@encode(short)) == 0) {
      short argument = [object shortValue];
      [invocation setArgument:&argument atIndex:index];
    } else if (strcmp(type,@encode(float)) == 0) {
      float argument = [object floatValue];
      [invocation setArgument:&argument atIndex:index];
    } else if (strcmp(type,@encode(double)) == 0) {
      double argument = [object doubleValue];
      [invocation setArgument:&argument atIndex:index];
    } else if (strcmp(type,@encode(unsigned long long)) == 0) {
      unsigned long long argument = [object longLongValue];
      [invocation setArgument:&argument atIndex:index];
    } else if (strcmp(type,@encode(long long)) == 0) {
      long long argument = [object longLongValue];
      [invocation setArgument:&argument atIndex:index];
    } else {
      [invocation setArgument:&object atIndex:index];
    }
    
    index ++;
  }
  
  [invocation invoke];
  
  if (signature.methodReturnLength) {
    [invocation getReturnValue:&returnValue];
    return returnValue;;
  }
  
  return nil;
}

@end
