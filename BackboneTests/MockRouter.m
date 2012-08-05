//
//  MockRouter.m
//  Backbone
//
//  Created by Edmond Leung on 8/4/12.
//  Copyright (c) 2012. All rights reserved.
//

#import "MockRouter.h"

@implementation MockRouter

@synthesize
  count = count_, query = query_, page = page_, contact = contact_,
  args = args_, first = first_, part = part_, rest = rest_, entity = entity_,
  queryArgs = queryArgs_, whatever = whatever_;

- (id)init {
  self = [super init];
  
  if (self) {
    [self route:@"*anything" name:@"anythingWithWhatever:"];
    [self route:@":entity?*args" name:@"queryWithEntity:args:"];
    [self route:@"*first/complex-:part/*rest" name:@"complexFirst:part:rest:"];
    [self route:@"splat/*args/end" name:@"splatWithArgs:"];
    [self route:@"contacts/:id" name:@"loadContactWithId:"];
    [self route:@"contacts/new" name:@"newContact"];
    [self route:@"contacts" name:@"contacts"];
    [self route:@"search/:query/p:page" name:@"searchWithQuery:page:"];
    [self route:@"search/:query" name:@"searchWithQuery:"];
    [self route:@"counter" name:@"counter"];
    [self route:@"noCallback" name:@"noCallback"];
    
    page_ = 0;
  }
  
  return self;
}

- (void)counter {
  count_ ++;
}

- (void)searchWithQuery:(NSString *)query {
  query_ = query;
}

- (void)searchWithQuery:(NSString *)query page:(NSUInteger)page {
  [self searchWithQuery:query];
  page_ = page;
}

- (void)contacts {
  contact_ = @"index";
}

- (void)newContact {
  contact_ = @"new";
}

- (void)loadContactWithId:(NSString *)id {
  contact_ = @"load";
}

- (void)splatWithArgs:(NSString *)args {
  args_ = args;
}

- (void)complexFirst:(NSString *)first
                part:(NSString *)part
                rest:(NSString *)rest {
  first_ = first;
  part_ = part;
  rest_ = rest;
}

- (void)queryWithEntity:(NSString *)entity args:(NSString *)args {
  entity_ = entity;
  queryArgs_ = args;
}

- (void)anythingWithWhatever:(NSString *)whatever {
  whatever_ = whatever;
}

@end
