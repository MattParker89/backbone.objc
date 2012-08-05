//
//  MockRouter.h
//  Backbone
//
//  Created by Edmond Leung on 8/4/12.
//  Copyright (c) 2012. All rights reserved.
//

#import "BackboneRouter.h"

@interface MockRouter : BackboneRouter {
  NSUInteger count_;
  NSString *query_;
  NSUInteger page_;
  NSString *contact_;
  NSString *args_;
  NSString *first_, *part_, *rest_;
  NSString *entity_, *queryArgs_;
  NSString *whatever_;
}

@property (nonatomic, assign) NSUInteger count;
@property (nonatomic, strong) NSString *query;
@property (nonatomic, assign) NSUInteger page;
@property (nonatomic, strong) NSString *contact;
@property (nonatomic, strong) NSString *args;
@property (nonatomic, strong) NSString *first, *part, *rest;
@property (nonatomic, strong) NSString *entity, *queryArgs;
@property (nonatomic, strong) NSString *whatever;

@end
