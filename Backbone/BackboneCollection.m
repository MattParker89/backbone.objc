//
//  BackboneCollection.m
//  Backbone
//
//  Created by Edmond Leung on 6/28/12.
//  Copyright (c) 2012. All rights reserved.
//

#import "BackboneCollection.h"
#import "ARCHelper.h"
#import "Mixin.h"
#import "NSArray+Backbone.h"
#import "Backbone.h"

@interface BackboneModel ()

- (BOOL)isValidForAttributes:(NSDictionary *)attributes
               errorCallback:(BackboneErrorBlock)errorCallback
                     options:(BackboneOptions)options;

@end

@implementation BackboneCollection

@synthesize
  model = model_, models = models_, comparator = comparator_, url = url_;

+ (void)initialize {
	if ([self class] == [BackboneCollection class]) {
    // Mixin BackboneEvents methods into BackboneCollection.
		[Mixin from:[BackboneEvents class] into:self];
  }
}

- (id)init {
  return [self initWithModels:nil];
}

- (id)initWithModels:(NSArray *)models {
  return [self initWithModel:nil models:models];
}

- (id)initWithModel:(Class)model models:(NSArray *)models {
  return [self initWithModel:model models:models options:0];
}

- (id)initWithModel:(Class)model
             models:(NSArray *)models
            options:(BackboneOptions)options {
  self = [super init];
  
  if (self) {
    if (!(model_ = model)) model_ = [BackboneModel class];
    models_ = AH_RETAIN([NSMutableArray array]);
    byId_ = AH_RETAIN([NSMutableDictionary dictionary]);
    byCid_ = AH_RETAIN([NSMutableDictionary dictionary]);
    
    __strong id this = self;
    __strong NSMutableDictionary *byId = byId_;
    
    onModelEvent_ = AH_BLOCK_COPY(^(NSNotification *notification) {
      NSString *event;
      BackboneModel *model;
      BackboneCollection *collection;
      BackboneOptions options;
      
      event = notification.name;
      
      if ([notification.object count] >= 2) {
        model = [notification.object objectAtIndex:0];
        collection = [notification.object objectAtIndex:1];
        
        if (([event isEqual:@"add"] ||
             [event isEqual:@"remove"]) && collection != this) return;
        if ([event isEqual:@"destroy"]) {
          options = [[notification.object objectAtIndex:2] integerValue];
          [this remove:model options:options];
        }
        if (model && [event isEqual:[NSString stringWithFormat:
                                     @"change:%@",
                                     [[model class] idAttribute]]]) {
          [byId removeObjectForKey:[model previous:[[model class] idAttribute]]];
          if (model.id) [byId setObject:model forKey:model.id];
        }
      }
      
      [this trigger:event argumentsArray:notification.object];
    });
    
    [self reset:models options:options];
  }
  
  return self;
}

- (NSUInteger)count {
  return models_.count;
}

- (id)objectAtIndex:(NSUInteger)index {
  return [models_ objectAtIndex:index];
}

- (void)insertObject:(id)anObject atIndex:(NSUInteger)index {
  [models_ insertObject:anObject atIndex:index];
}

- (void)removeObjectAtIndex:(NSUInteger)index {
  [models_ removeObjectAtIndex:index];
}

- (void)addObject:(id)anObject {
  [models_ addObject:anObject];
}

- (void)removeLastObject {
  [models_ removeLastObject];
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject {
  [models_ replaceObjectAtIndex:index withObject:anObject];
}

- (NSArray *)models {
  return [NSArray arrayWithArray:models_];
}

- (NSArray *)toJSON {
  return [models_ toJSON];
}

- (void)add:(id)modelOrAttributes {
  [self add:modelOrAttributes options:0];
}

- (void)add:(id)modelOrAttributes options:(BackboneOptions)options {
  [self add:modelOrAttributes at:-1 options:options];
}

- (void)add:(id)modelOrAttributes at:(NSUInteger)at {
  [self add:modelOrAttributes at:at options:0];
}

- (void)add:(id)modelOrAttributes
    options:(BackboneOptions)options
errorCallback:(BackboneErrorBlock)errorCallback {
  [self add:modelOrAttributes
         at:-1
    options:options
errorCallback:errorCallback];
}

- (void)add:(id)modelOrAttributes
         at:(NSUInteger)at 
errorCallback:(BackboneErrorBlock)errorCallback {
  [self add:modelOrAttributes
         at:at
    options:0
errorCallback:errorCallback];
}

- (void)add:(id)modelOrAttributes
         at:(NSUInteger)at
    options:(BackboneOptions)options {
  [self add:modelOrAttributes at:at options:options errorCallback:nil];
}

- (void)add:(id)modelOrAttributes
         at:(NSUInteger)at
    options:(BackboneOptions)options
errorCallback:(BackboneErrorBlock)errorCallback {
  [self addModels:@[modelOrAttributes]
               at:at
          options:options
    errorCallback:errorCallback];
}

- (void)addModels:(NSArray *)models {
  [self addModels:models options:0];
}

- (void)addModels:(NSArray *)models options:(BackboneOptions)options {
  [self addModels:models at:-1 options:options];
}

- (void)addModels:(NSArray *)models at:(NSUInteger)at {
  [self addModels:models at:at options:0];
}

- (void)addModels:(NSArray *)models
          options:(BackboneOptions)options
    errorCallback:(BackboneErrorBlock)errorCallback {
  [self addModels:models at:-1 options:options errorCallback:nil];
}

- (void)addModels:(NSArray *)models
               at:(NSUInteger)at
    errorCallback:(BackboneErrorBlock)errorCallback {
  [self addModels:models at:at options:0 errorCallback:nil];
}

- (void)addModels:(NSArray *)models
               at:(NSUInteger)at
          options:(BackboneOptions)options {
  [self addModels:models at:at options:options errorCallback:nil];
}

- (void)addModels:(NSArray *)models
               at:(NSUInteger)at
          options:(BackboneOptions)options
    errorCallback:(BackboneErrorBlock)errorCallback {
  NSUInteger index;
  NSMutableArray *mutableModels, *dups;
  BackboneModel *model;
  NSString *cid, *id;
  NSMutableDictionary *cids, *ids;
  
  index = 0;
  mutableModels = [NSMutableArray array];
  dups = [NSMutableArray array];
  cids = [NSMutableDictionary dictionary];
  ids = [NSMutableDictionary dictionary];
  
  // Begin by turning bare objects into model references, and preventing
  // invalid models or duplicate models from being added.
  for (model in models) {
    if (!(model = [self prepareModel:model
                       errorCallback:errorCallback 
                             options:options])) {
      @throw([NSException 
              exceptionWithName:@"InvalidModelException"
              reason:@"Can't add an invalid model to a collection"
              userInfo:nil]);
    }
    [mutableModels addObject:model];
    cid = model.cid;
    id = model.id;
    
    if ([cids objectForKey:cid] || [byCid_ objectForKey:cid] ||
        ((id != nil) && ([ids objectForKey:id] || [byId_ objectForKey:id]))) {
      [dups addObject:@(index)];
    }
    
    [cids setObject:model forKey:cid];
    if (model.id) [ids setObject:model forKey:id];
    
    index ++;
  }
  
  // Remove duplicates.
  index = dups.count;
  while (index --) {
    [mutableModels removeObjectAtIndex:index];
  }
  
  // Listen to added models' events, and index models for lookup by
  // id and by cid.
  for (model in mutableModels) {
    [model on:@"all" call:onModelEvent_ observer:self];
    [byCid_ setObject:model forKey:model.cid];
    if (model.id != nil) [byId_ setObject:model forKey:model.id];
  }
  
  // Insert models into the collection, re-sorting if needed, and triggering
  // add events unless silenced.
  index = at != -1 ? at : models_.count;
  for (model in [mutableModels reverseObjectEnumerator]) {
    [models_ insertObject:model atIndex:index];
  }
  if (self.comparator) [self sortWithOptions:BackboneSetSilently];
  
  if (options & BackboneSetSilently) return;

  for (model in models_) {
    if (![cids objectForKey:model.cid]) continue;
    NSNumber *index = @([models_ indexOfObject:model]);
    [model trigger:@"add" arguments:
     model, self, @(options), index, nil];
  }
}

- (void)remove:(id)modelOrId {
  [self remove:modelOrId options:0];
}

- (void)remove:(id)modelOrId options:(BackboneOptions)options {
  [self removeModels:@[modelOrId] options:options];
}

- (void)removeModels:(NSArray *)models {
  [self removeModels:models options:0];
}

- (void)removeModels:(NSArray *)models options:(BackboneOptions)options {
  id model;
  BackboneModel *getModel;
  NSNumber *index;
  
  for (model in models) {
    getModel = [self getByCid:model];
    if (!getModel) getModel = [self get:model];
    if (!(model = getModel)) continue;
    if ([model id]) [byId_ removeObjectForKey:[model id]];
    [byCid_ removeObjectForKey:[model cid]];
    index = @([self indexOfObject:model]);
    [models_ removeObject:model];
    if (!(options & BackboneSetSilently)) {
      [model trigger:@"remove" arguments:
       model, self, @(options), index, nil];
    }
    [self removeReference:model];
  }
}

- (BackboneModel *)push:(id)modelOrAttributes {
  return [self push:modelOrAttributes options:0];
}

- (BackboneModel *)push:(id)modelOrAttributes
                options:(BackboneOptions)options {
  return [self push:modelOrAttributes options:options errorCallback:nil];
}


- (BackboneModel *)push:(id)modelOrAttributes
                options:(BackboneOptions)options
          errorCallback:(BackboneErrorBlock)errorCallback {
  BackboneModel *model = [self prepareModel:modelOrAttributes
                              errorCallback:errorCallback
                                    options:options];
  [self add:model options:options];
  return model;
}

- (BackboneModel *)pop {
  return [self popWithOptions:0];
}

- (BackboneModel *)popWithOptions:(BackboneOptions)options {
  BackboneModel *model = [self at:models_.count - 1];
  [self remove:model options:options];
  return model;
}

- (BackboneModel *)unshift:(id)modelOrAttributes {
  return [self unshift:modelOrAttributes options:0];
}

- (BackboneModel *)unshift:(id)modelOrAttributes
                   options:(BackboneOptions)options {
  return [self unshift:modelOrAttributes options:options errorCallback:nil];
}

- (BackboneModel *)unshift:(id)modelOrAttributes
                   options:(BackboneOptions)options
             errorCallback:(BackboneErrorBlock)errorCallback {
  BackboneModel *model = [self prepareModel:modelOrAttributes
                              errorCallback:errorCallback
                                    options:options];
  [self add:model at:0 options:options];
  return model;
}

- (BackboneModel *)shift {
  return [self shiftWithOptions:0];
}

- (BackboneModel *)shiftWithOptions:(BackboneOptions)options {
  BackboneModel *model = [self at:0];
  [self remove:model options:options];
  return model;
}

- (BackboneModel *)getByCid:(id)cidOrModel {
  if (!cidOrModel) return nil;
  if ([cidOrModel isKindOfClass:[BackboneModel class]]) {
    cidOrModel = [cidOrModel cid];
  }
  return [byCid_ objectForKey:cidOrModel];
}

- (BackboneModel *)get:(id)idOrModel {
  if (!idOrModel) return nil;
  if ([idOrModel isKindOfClass:[BackboneModel class]]) {
    idOrModel = [idOrModel id];
  }
  return [byId_ objectForKey:idOrModel];
}

- (BackboneModel *)at:(NSUInteger)index {
  return [models_ objectAtIndex:index];
}

- (NSArray *)where:(NSDictionary *)attributes {
  BackboneModel *model;
  NSString *key;
  NSMutableArray *models;
  BOOL match;
  
  if (attributes.count == 0) return @[];
  
  models = [NSMutableArray array];
  
  for (model in self) {
    match = YES;
    for (key in attributes) {
      if ([attributes objectForKey:key] != [model get:key]) {
        match = NO;
        break;
      }
    }
    if (match) [models addObject:model];
  }
  
  return [NSArray arrayWithArray:models];
}

- (void)sort {
  [self sortWithOptions:0];
}

- (void)sortWithOptions:(BackboneOptions)options {
  if (!self.comparator) {
    @throw([NSException 
            exceptionWithName:@"InvalidComparatorException"
            reason:@"Cannot sort a set without a comparator"
            userInfo:nil]);
  }
  
  models_ = [NSMutableArray arrayWithArray:
             [models_ sortedArrayUsingComparator:self.comparator]];
  if (!(options & BackboneSetSilently)) {
    [self trigger:@"reset"
        arguments:self, @(options), nil];
  }
}

- (NSArray *)pluck:(NSString *)attribute {
  BackboneModel *model;
  NSMutableArray *plucked;
  
  plucked = [NSMutableArray array];
  
  for (model in models_) {
    [plucked addObject:[model get:attribute]];
  }
  
  return [NSArray arrayWithArray:plucked];
}

- (void)reset:(NSArray *)models {
  [self reset:models options:0];
}

- (void)reset:(NSArray *)models options:(BackboneOptions)options {
  BackboneModel *model;
  
  models || (models = @[]);
  
  for (model in models_) {
    [self removeReference:model];
  }
  
  [models_ removeAllObjects];
  [byId_ removeAllObjects];
  [byCid_ removeAllObjects];
  
  [self addModels:models options:options | BackboneSetSilently];
  
  if (!(options & BackboneSetSilently)) {
    [self trigger:@"reset" arguments:
     self, @(options), nil];
  }
}

- (void)fetch {
  [self fetchWithOptions:0];
}

- (void)fetchWithOptions:(BackboneOptions)options {
  [self fetchWithSuccessCallback:nil errorCallback:nil options:options];
}

- (void)fetchWithSuccessCallback:(BackboneSyncSuccessBlock)successCallback
                   errorCallback:(BackboneErrorBlock)errorCallback
                         options:(BackboneOptions)options {
  BackboneSyncSuccessBlock wrappedSuccessCallback;
  
  wrappedSuccessCallback = ^(BackboneCollection *collection, id response) {
    NSArray *models = [self parse:response];
    
    if (options & BackboneAddToCollection) {
      [self addModels:models options:options];
    } else {
      [self reset:models options:options];
    }
    
    if (successCallback) successCallback(collection, response);
  };
  
  if ([[self class] respondsToSelector:
       @selector(sync:method:successCallback:errorCallback:)]) {
    [[self class] sync:self
                method:BackboneSyncCRUDMethodRead
       successCallback:wrappedSuccessCallback
         errorCallback:errorCallback];
  } else {
    [Backbone sync:self
            method:BackboneSyncCRUDMethodRead
   successCallback:wrappedSuccessCallback
     errorCallback:errorCallback];
  }
}

- (BackboneModel *)create:(id)modelOrAttributes {
  return [self create:modelOrAttributes options:0];
}

- (BackboneModel *)create:(id)modelOrAttributes
                  options:(BackboneOptions)options {
  return [self create:modelOrAttributes
      successCallback:nil
        errorCallback:nil
              options:options];
}

- (BackboneModel *)create:(id)modelOrAttributes 
          successCallback:(BackboneSyncSuccessBlock)successCallback
            errorCallback:(BackboneErrorBlock)errorCallback
                  options:(BackboneOptions)options {
  BackboneModel *model;
  BackboneSyncSuccessBlock wrappedSuccessCallback;
  
  model = [self prepareModel:modelOrAttributes
               errorCallback:errorCallback
                     options:options];
  if (!model) return nil;
  if (!(options & BackboneSyncWait)) [self add:model options:options];
  
  wrappedSuccessCallback = ^(BackboneModel *nextModel, id response) {
    if (options & BackboneSyncWait) [self add:nextModel options:options];
    if (successCallback) {
      successCallback(nextModel, response);
    } else {
      [nextModel trigger:@"sync" arguments:
       model, response, @(options), nil];
    }
  };
  
  [model save:nil
      options:options
successCallback:wrappedSuccessCallback
errorCallback:errorCallback];
  
  return model;
}

- (NSArray *)parse:(NSArray *)response {
  return response;
}

- (BackboneModel *)prepareModel:(id)modelOrAttributes
                  errorCallback:(BackboneErrorBlock)errorCallback
                        options:(BackboneOptions)options {
  NSDictionary *attributes;
  BackboneModel *model;
  
  model = nil;
  
  if (![modelOrAttributes isKindOfClass:[BackboneModel class]]) {
    attributes = modelOrAttributes;
    model = AH_AUTORELEASE([[[self.model class] alloc]
                            initWithAttributes:attributes
                            collection:self
                            options:options]);
    if (![model isValidForAttributes:attributes
                       errorCallback:errorCallback
                             options:options]) {
      model = nil;
    }
  } else if (![modelOrAttributes collection]) {
    model = modelOrAttributes;
    model.collection = self;
  } else {
    model = modelOrAttributes;
  }
  
  return model;
}

- (void)removeReference:(BackboneModel *)model {
  if (model.collection) model.collection = nil;
  [model off:@"all" call:onModelEvent_];
}

- (void)dealloc {
  self.model = nil;
  self.comparator = nil;
  self.url = nil;
  
  AH_RELEASE(models_);
  AH_RELEASE(byCid_);
  AH_RELEASE(byId_);
  AH_BLOCK_RELEASE(onModelEvent_);
  
  // Remove all events binded to the collection.
  [self off];
  
  AH_SUPER_DEALLOC;
}

@end
