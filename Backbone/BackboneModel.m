//
//  BackboneModel.m
//  Backbone
//
//  Created by Edmond Leung on 5/12/12.
//  Copyright (c) 2012. All rights reserved.
//

#import <objc/runtime.h>
#import "BackboneModel.h"
#import "ARCHelper.h"
#import "Mixin.h"
#import "NSDictionary+Backbone.h"
#import "Backbone.h"

NSArray *getPropertyAttributes(objc_property_t property) {
  return [@(property_getAttributes(property)) 
          componentsSeparatedByString:@","];
}

void *attributeGetter(BackboneModel *self, SEL _cmd) {
  return (__AH_BRIDGE void *)[self get:NSStringFromSelector(_cmd)];
}

@implementation BackboneModel

@synthesize 
  id = id_, cid = cid_, attributes = attributes_, url, urlRoot = urlroot_,
  collection = collection_,
  changedAttributes;

+ (void)initialize {
	if ([self class] == [BackboneModel class]) {
    // Mixin BackboneEvents methods into BackboneModel.
		[Mixin from:[BackboneEvents class] into:self];
  }
}

+ (BOOL)resolveInstanceMethod:(SEL)sel {
  objc_property_t property;
  
  property = class_getProperty([self class], 
                               [NSStringFromSelector(sel) 
                                cStringUsingEncoding:NSUTF8StringEncoding]);
  
  if (property) {
    // Only resolve getters for dynamic properties.
    if ([getPropertyAttributes(property) containsObject:@"D"] &&
        ![NSStringFromSelector(sel) hasPrefix:@"set"]) {
      class_addMethod([self class], sel, (IMP)attributeGetter, "@@:");
      return YES;
    }
  }
  
  return [super resolveInstanceMethod:sel];
}

+ (NSString *)idAttribute {
  return @"id";
}

- (id)init {
  return [self initWithAttributes:nil];
}

- (id)initWithAttributes:(NSDictionary *)attributes {
  return [self initWithAttributes:attributes options:0];
}

- (id)initWithAttributes:(NSDictionary *)attributes
                 options:(BackboneOptions)options {
  return [self initWithAttributes:attributes collection:nil options:options];
}

- (id)initWithAttributes:(NSDictionary *)attributes
              collection:(BackboneCollection *)collection {
  return [self initWithAttributes:attributes collection:collection options:0];
}

- (id)initWithAttributes:(NSDictionary *)attributes
              collection:(BackboneCollection *)collection
                 options:(BackboneOptions)options {
  self = [super init];
  
  if (self) {
    if (!attributes) attributes = @{};
    
    if (options & BackboneParseAttributes) attributes = [self parse:attributes];
    if ([[self class] respondsToSelector:@selector(defaults)]) {
      attributes = [[[self class] defaults] extend:attributes];
    }
    collection_ = AH_RETAIN(collection);
    attributes_ = [[NSMutableDictionary alloc] init];
    cid_ = [[@"c" stringByAppendingString:
             [[NSProcessInfo processInfo] globallyUniqueString]] copy];
    changed_ = [[NSMutableDictionary alloc] init];
    silent_ = [[NSMutableArray alloc] init];
    pending_ = [[NSMutableArray alloc] init];
    
    [self set:attributes options:BackboneSetSilently];
    
    // Reset change tracking.
    [changed_ removeAllObjects];
    [silent_ removeAllObjects];
    [pending_ removeAllObjects];
    previousAttributes_ = [[NSMutableDictionary alloc] 
                            initWithDictionary:attributes_];
  }
  
  return self;
}

- (NSDictionary *)toJSON {
  return [attributes_ toJSON];
}

- (id)get:(NSString *)attribute {
  return [attributes_ objectForKey:attribute];
}

- (BOOL)has:(NSString *)attribute {
  id value = [self get:attribute];
  return (value && ![value isEqual:[NSNull null]]);
}

- (BOOL)set:(NSString *)attribute value:(id)value {
  return [self set:attribute value:value options:0];
}

- (BOOL)set:(NSString *)attribute
      value:(id)value
    options:(BackboneOptions)options {
  return [self set:attribute value:value options:options errorCallback:nil];
}

- (BOOL)set:(NSString *)attribute
      value:(id)value
    options:(BackboneOptions)options
errorCallback:(BackboneErrorBlock)errorCallback {
  return [self set:@{attribute: value}
           options:options errorCallback:errorCallback];
}

- (BOOL)set:(NSDictionary *)attributes {
  return [self set:attributes options:0];
}

- (BOOL)set:(NSDictionary *)attributes options:(BackboneOptions)options {
  return [self set:attributes options:options errorCallback:nil];
}

- (BOOL)set:(NSDictionary *)attributes
    options:(BackboneOptions)options
errorCallback:(BackboneErrorBlock)errorCallback {
  NSString *idAttribute, *attribute;
  NSMutableArray *changes;
  id value;
  
  // Run validation.
  if (!(options & BackboneSetSilently) && 
      ![self isValidForAttributes:attributes
                    errorCallback:errorCallback
                          options:options]) 
    return NO;
  
  // Check for changes of id.
  idAttribute = [[self class] idAttribute];
  if ([attributes.allKeys containsObject:idAttribute]) {
    self.id = [attributes objectForKey:idAttribute];
  }
  
  changes = [NSMutableArray array];
  
  // For each set attribute...
  for (attribute in attributes) {
    value = [attributes objectForKey:attribute];
    
    // If the new and current value differ, record the change.
    if (![[attributes_ objectForKey:attribute] isEqual:value]) {
      [((options & BackboneSetSilently) ? silent_ : changes)
       addObject:attribute];
    }
    
    // Update the current value.
    [attributes_ setObject:value forKey:attribute];
    
    // If the new and previous value differ, record the change.  If not, then 
    // remove changes for this attribute.
    if (![[previousAttributes_ objectForKey:attribute] isEqual:value]) {
      [changed_ setObject:value forKey:attribute];
      if (!(options & BackboneSetSilently)) [pending_ addObject:attribute];
    } else {
      [changed_ removeObjectForKey:attribute];
      [pending_ removeObject:attribute];
    }
  }
  
  // Fire the "change" events.
  if (!(options & BackboneSetSilently)) [self change:changes];
  return YES;
}

- (BOOL)unset:(NSString *)attribute {
  return [self unset:attribute options:0];
}

- (BOOL)unset:(NSString *)attribute options:(BackboneOptions)options {
  return [self unset:attribute options:options errorCallback:nil];
}

- (BOOL)unset:(NSString *)attribute
      options:(BackboneOptions)options
errorCallback:(BackboneErrorBlock)errorCallback {
  return [self unsetAttributes:@[attribute] 
                       options:options
             withErrorCallback:errorCallback]; 
}

- (BOOL)unsetAttributes:(NSArray *)attributes
                options:(BackboneOptions)options
      withErrorCallback:(BackboneErrorBlock)errorCallback {
  NSMutableDictionary *unsetAttributes;
  NSString *idAttribute, *attribute;
  NSMutableArray *changes;
  
  // Run validation.
  unsetAttributes = [NSMutableDictionary dictionaryWithDictionary:attributes_];
  for (attribute in attributes) {
    [unsetAttributes setObject:[NSNull null] forKey:attribute];
  }
  if (!(options & BackboneSetSilently) &&
      ![self isValidForAttributes:unsetAttributes
                    errorCallback:errorCallback
                          options:options]) {
    return NO;
  }
  
  // Check for changes of id.
  idAttribute = [[self class] idAttribute];
  if ([attributes containsObject:idAttribute]) {
    self.id = nil;
  }
  
  changes = [NSMutableArray array];
  
  // For each unset attribute...
  for (attribute in attributes) {
    // If the new and current value differ, record the change.
    if ([attributes_ objectForKey:attribute]) {
      [((options & BackboneSetSilently) ? silent_ : changes)
       addObject:attribute];
    }
    
    // Delete the current value.
    [attributes_ removeObjectForKey:attribute];
    
    // If the new and previous value differ, record the change.  If not, then 
    // remove changes for this attribute.
    if ([previousAttributes_ objectForKey:attribute]) {
      [changed_ setObject:[NSNull null] forKey:attribute];
      if (!(options & BackboneSetSilently)) [pending_ addObject:attribute];
    } else {
      [changed_ removeObjectForKey:attribute];
      [pending_ removeObject:attribute];
    }
  }
  
  // Fire the "change" events.
  if (!(options & BackboneSetSilently)) [self change:changes];
  return YES;
}

- (BOOL)clear {
  return [self clearWithErrorCallback:nil];
}

- (BOOL)clearWithErrorCallback:(BackboneErrorBlock)errorCallback {
  return [self clearWithOptions:0 errorCallback:nil];
}

- (BOOL)clearWithOptions:(BackboneOptions)options
           errorCallback:(BackboneErrorBlock)errorCallback {
  return [self unsetAttributes:attributes_.allKeys
                       options:options
             withErrorCallback:errorCallback];
}

- (void)fetch {
  [self fetchWithOptions:0];
}

- (void)fetchWithOptions:(BackboneOptions)options {
  [self fetchWithOptions:options successCallback:nil errorCallback:nil];
}

- (void)fetchWithOptions:(BackboneOptions)options
         successCallback:(BackboneSyncSuccessBlock)successCallback
           errorCallback:(BackboneErrorBlock)errorCallback {
  BackboneSyncSuccessBlock wrappedSuccessCallback;
  
  wrappedSuccessCallback = ^(BackboneModel *model, id response) {
    if (![model set:[model parse:response] options:options]) return;
    if (successCallback) successCallback(model, response);
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

- (BOOL)save {
  return [self saveWithOptions:0];
}

- (BOOL)save:(NSDictionary *)attributes {
  return [self save:attributes options:0];
}

- (BOOL)save:(NSDictionary *)attributes options:(BackboneOptions)options {
  return [self save:attributes
            options:options
    successCallback:nil
      errorCallback:nil];
}

- (BOOL)saveWithOptions:(BackboneOptions)options {
  return [self saveWithOptions:options successCallback:nil errorCallback:nil];
}

- (BOOL)saveWithOptions:(BackboneOptions)options
        successCallback:(BackboneSyncSuccessBlock)successCallback
          errorCallback:(BackboneErrorBlock)errorCallback {
  return [self save:nil
            options:options
    successCallback:successCallback
      errorCallback:errorCallback];
}

- (BOOL)save:(NSDictionary *)attributes
     options:(BackboneOptions)options
successCallback:(BackboneSyncSuccessBlock)successCallback
errorCallback:(BackboneSyncSuccessBlock)errorCallback {
  BackboneErrorBlock wrappedErrorCallback;
  NSDictionary *current;
  BackboneSyncCRUDMethod method;
  BackboneSyncSuccessBlock wrappedSuccessCallback;
  
  wrappedErrorCallback = ^(id subject, NSError *error) {
    if (errorCallback) errorCallback(subject, error);
  };
  
  current = nil;
  
  // If we're "wait"-ing to set changed attributes, validate early.
  if (options & BackboneSyncWait) {
    if (![self isValidForAttributes:attributes
                      errorCallback:wrappedErrorCallback
                            options:options]) {
      return false;
    }
    current = [NSDictionary dictionaryWithDictionary:attributes_];
  }
  
  // Regular saves set attributes before persisting to the server.
  BackboneOptions silentOptions = options | BackboneSetSilently;
  if (attributes && ![self set:attributes options:silentOptions]) {
    return NO;
  }
  
  method = [self isNew] ? 
    BackboneSyncCRUDMethodCreate : BackboneSyncCRUDMethodUpdate;
  
  wrappedSuccessCallback = ^(BackboneModel *model, id response) {
    // After a successful server-side save, the client is (optionally)
    // updated with the server-side state.
    
    BackboneOptions setOptions = options;
    NSDictionary *serverAttributes = [model parse:response];
    
    if (options & BackboneSyncWait) {
      setOptions = options & ~BackboneSyncWait;
      if (attributes) {
        serverAttributes = [attributes extend:serverAttributes];
      }
    }
    
    if (![model set:serverAttributes options:setOptions]) return;
    
    if (successCallback) {
      successCallback(model, response);
    } else {
      [model trigger:@"sync" arguments:
       model, response, @(options), nil];
    }
  };
  
  // Finish configuring and sending the request.
  if ([[self class] respondsToSelector:
       @selector(sync:method:successCallback:errorCallback:)]) {
    [[self class] sync:self
                method:method
       successCallback:wrappedSuccessCallback
         errorCallback:errorCallback];
  } else {
    [Backbone sync:self
            method:method
   successCallback:wrappedSuccessCallback
     errorCallback:errorCallback];
  }
  
  if (options & BackboneSyncWait) {
    [self clearWithOptions:silentOptions errorCallback:wrappedErrorCallback];
    [self set:current options:silentOptions errorCallback:wrappedErrorCallback];
  }
  
  return YES;
}

- (BOOL)destroy {
  return [self destroyWithOptions:0 successCallback:nil errorCallback:nil];
}

- (BOOL)destroyWithOptions:(BackboneOptions)options
           successCallback:(BackboneSyncSuccessBlock)successCallback
             errorCallback:(BackboneErrorBlock)errorCallback {
  BackboneSyncSuccessBlock wrappedSuccessCallback;
  
  void(^triggerDestroy)() = ^() {
    [self trigger:@"destroy" arguments:
     self, collection_, @(options), nil];
  };
  
  if ([self isNew]) {
    triggerDestroy();
    return NO;
  }
  
  wrappedSuccessCallback = ^(BackboneModel *model, id response) {
    if (options & BackboneSyncWait) triggerDestroy();
    if (successCallback) {
      successCallback(model, response);
    } else {
      [model trigger:@"sync"
           arguments:model, response, @(options), nil];
    }
  };
  
  if ([[self class] respondsToSelector:
       @selector(sync:method:successCallback:errorCallback:)]) {
    [[self class] sync:self
                method:BackboneSyncCRUDMethodDelete
       successCallback:wrappedSuccessCallback
         errorCallback:errorCallback];
  } else {
    [Backbone sync:self
            method:BackboneSyncCRUDMethodDelete
   successCallback:wrappedSuccessCallback
     errorCallback:errorCallback];
  }
  
  if (!(options & BackboneSyncWait)) triggerDestroy();
  return YES;
}

- (BOOL)isValid {
  return 
    ![self respondsToSelector:@selector(validate:)] ||
    ![self validate:attributes_];
}


- (BOOL)isValidForAttributes:(NSDictionary *)attributes
               errorCallback:(BackboneErrorBlock)errorCallback
                     options:(BackboneOptions)options {
  NSError *error;
  
  if (![self respondsToSelector:@selector(validate:)]) return YES;
  if (!(error = [self validate:[attributes_ extend:attributes]])) return YES;
  
  if (errorCallback) {
    errorCallback(self, error);
  } else {
    [self trigger:@"error" arguments:
     self, error, @(options), nil]; 
  }
  
  return NO;
}

- (NSString *)url {
  NSString *base, *stringId, *encodedId, *modelUrl;
  
  if (!(base = self.urlRoot ? self.urlRoot : collection_.url)) {
    @throw([NSException 
            exceptionWithName:@"URLNotFoundException"
            reason:@"A \"url\" property or method must be specified"
            userInfo:nil]);
  }
  
  if ([self isNew]) return base;
  
  stringId = [NSString stringWithFormat:@"%@", self.id];
  encodedId = (__AH_BRIDGE NSString *)
    CFURLCreateStringByAddingPercentEscapes(NULL, 
                                            (__AH_BRIDGE CFStringRef)stringId,
                                            NULL, 
                                            (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                            kCFStringEncodingUTF8);
  
  modelUrl = [base stringByAppendingFormat:@"%@%@",
              ([base characterAtIndex:base.length - 1] == '/' ? @"" : @"/"),
              encodedId];
  
  CFRelease((__AH_BRIDGE CFStringRef)encodedId);
  
  return modelUrl;
}

- (NSDictionary *)parse:(NSDictionary *)response {
  return response;
}

- (id)clone {
  return AH_AUTORELEASE([[[self class] alloc] initWithAttributes:attributes_]);
}

- (BOOL)isNew {
  return !self.id;
}

- (void)change {
  [self change:nil];
}

- (void)change:(NSArray *)changes {
  [self change:changes options:0];
}

- (void)change:(NSArray *)changes options:(BackboneOptions)options {
  BOOL changing;
  NSString *attribute;
  NSMutableArray *allChanges;
  NSMutableDictionary *changed;
  
  changing = changing_;
  changing_ = YES;
  
  // Silent changes become pending changes.
  for (attribute in silent_) [pending_ addObject:attribute];
  
  // Silent changes are triggered.
  [(allChanges = [NSMutableArray arrayWithArray:changes])
   addObjectsFromArray:silent_];
  [silent_ removeAllObjects];
  for (attribute in allChanges) {
    [self trigger:[@"change:" stringByAppendingString:attribute]
        arguments:
     self, [self get:attribute], changes, 
     @(options), nil];
  }
  if (changing) return;
  
  // Continue firing "change" events while there are pending changes.
  while (pending_.count > 0) {
    [pending_ removeAllObjects];
    [self trigger:@"change" arguments:
     self, changes, @(options), nil];
    
    // Pending and silent changes still remain.
    changed = [NSMutableDictionary dictionaryWithDictionary:changed_];
    for (attribute in changed) {
      if ([pending_ containsObject:attribute] || 
          [silent_ containsObject:attribute]) continue;
      [changed_ removeObjectForKey:attribute];
    }
    
    AH_RELEASE(previousAttributes_);
    previousAttributes_ =
      [[NSMutableDictionary alloc] initWithDictionary:attributes_];
  }
  
  changing_ = NO;
}

- (BOOL)hasChanged {
  return changed_.allKeys.count > 0;
}

- (BOOL)hasChanged:(NSString *)attribute {
  if (!attribute) return [self hasChanged];
  return !![changed_ objectForKey:attribute];
}

- (NSDictionary *)changedAttributes {
  return 
    [self hasChanged] ? [NSDictionary dictionaryWithDictionary:changed_] : nil;
}

- (NSDictionary *)changedAttributes:(NSDictionary *)diff {
  if (!diff) return self.changedAttributes;
  
  NSString *attribute;
  id value;
  NSMutableDictionary *changed;
  
  changed = nil;
  
  for (attribute in diff) {
    value = [diff objectForKey:attribute];
    if ([[previousAttributes_ objectForKey:attribute] isEqual:value]) continue;
    if (!changed) changed = [NSMutableDictionary dictionary];
    [changed setObject:value forKey:attribute];
  }
  
  return changed;
}

- (id)previous:(NSString *)attribute {
  if (!attribute || !previousAttributes_) return nil;
  return [previousAttributes_ objectForKey:attribute];
}

- (NSDictionary *)previousAttributes {
  return [NSDictionary dictionaryWithDictionary:previousAttributes_];
}

- (void)dealloc {
  self.id = nil;
  self.cid = nil;
  self.urlRoot = nil;
  
  AH_RELEASE(attributes_);
  AH_RELEASE(previousAttributes_);
  AH_RELEASE(collection_);
  AH_RELEASE(changed_);
  AH_RELEASE(silent_);
  AH_RELEASE(pending_);
  
  // Remove all events binded to the model.
  [self off];
  
  AH_SUPER_DEALLOC;
}

@end
