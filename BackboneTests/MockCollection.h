//
//  MockCollection.h
//  Backbone
//
//  Created by Edmond Leung on 7/12/12.
//  Copyright (c) 2012. All rights reserved.
//

#import "BackboneCollection.h"

@interface MockCollection : BackboneCollection

+ (NSDictionary *)lastRequest;
+ (void)clearLastRequest;

@end
