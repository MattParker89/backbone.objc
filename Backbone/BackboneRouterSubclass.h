//
//  BackboneRouterSubclass.h
//  Backbone
//
//  Created by Edmond Leung on 8/9/12.
//  Copyright (c) 2012. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSObject+Backbone.h"

@interface BackboneRouter ()

- (NSRegularExpression *)routeToRegExp:(NSString *)route;
- (NSArray *)extractParameters:(NSRegularExpression *)route
                           url:(NSString *)url;

@end
