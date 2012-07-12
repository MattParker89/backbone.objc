//
//  MockModel.h
//  Backbone
//
//  Created by Edmond Leung on 5/27/12.
//  Copyright (c) 2012. All rights reserved.
//

#import "BackboneModel.h"

@interface MockModel : BackboneModel {
  BOOL validated_;
}

@property (nonatomic, assign) BOOL validated;
@property (nonatomic, readonly) NSNumber *one;

+ (NSDictionary *)lastRequest;
+ (void)clearLastRequest;

@end
