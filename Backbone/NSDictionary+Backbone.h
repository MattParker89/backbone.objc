//
//  NSDictionary+Backbone.h
//  Backbone
//
//  Created by Edmond Leung on 5/26/12.
//  Copyright (c) 2012. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (Backbone)

- (NSDictionary *)extend:(NSDictionary *)dictionary;

- (NSString *)encodedURL;

- (NSDictionary *)toJSON;

@end
