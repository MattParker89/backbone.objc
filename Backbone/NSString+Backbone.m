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
    (NULL, (CFStringRef)self, NULL, 
     (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ", 
     kCFStringEncodingUTF8);
  
  return AH_AUTORELEASE((NSString *)urlString);
}

@end
