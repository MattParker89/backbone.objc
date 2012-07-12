//
//  NSArray+Backbone.h
//  Backbone
//
//  Created by Edmond Leung on 5/28/12.
//  Copyright (c) 2012. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (Backbone)

- (NSString *)encodedURL;

- (NSArray *)toJSON;

@end
