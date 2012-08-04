//
//  NSString+Backbone.m
//  Backbone
//
//  Created by Edmond Leung on 5/28/12.
//  Copyright (c) 2012. All rights reserved.
//

#import "NSString+Backbone.h"
#import "ARCHelper.h"

@implementation NSString (Backbone)

- (NSString *)encodedURL {
  CFStringRef urlString = CFURLCreateStringByAddingPercentEscapes
    (NULL, (__AH_BRIDGE CFStringRef)self, NULL, 
     (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ", 
     kCFStringEncodingUTF8);
  
  return AH_AUTORELEASE((__AH_BRIDGE NSString *)urlString);
}

@end
