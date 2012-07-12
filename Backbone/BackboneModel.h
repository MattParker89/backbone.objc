//
//  BackboneModel.h
//  Backbone
//
//  Created by Edmond Leung on 5/12/12.
//  Copyright (c) 2012. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BackboneTypes.h"
#import "BackboneEvents.h"

@class BackboneCollection;

@protocol BackboneModel <NSObject>

@optional

+ (NSString *)idAttribute;
+ (NSDictionary *)defaults;
+ (void)sync:(BackboneModel *)model
      method:(BackboneSyncCRUDMethod)method 
successCallback:(BackboneSyncSuccessBlock)successCallback
errorCallback:(BackboneErrorBlock)errorCallback;

- (NSError *)validate:(NSDictionary *)attributes;

@end

@interface BackboneModel : NSObject<BackboneModel, BackboneEventsMixin> {
 @private
  id id_;
  NSString *cid_;
  NSMutableDictionary *attributes_;
  NSString *urlRoot_;
  NSMutableDictionary *previousAttributes_;
  BackboneCollection *collection_;
  NSMutableDictionary *changed_;
  NSMutableArray *silent_;
  NSMutableArray *pending_;
  BOOL changing_;
}

@property (nonatomic, copy) id id;
@property (nonatomic, copy) NSString *cid;
@property (nonatomic, readonly) NSDictionary *attributes;
@property (nonatomic, readonly) NSString *url;
@property (nonatomic, copy) NSString *urlRoot;
@property (nonatomic, readonly) NSDictionary *changedAttributes;
@property (nonatomic, readonly) NSDictionary *previousAttributes;
@property (nonatomic, retain) BackboneCollection *collection;

- (id)initWithAttributes:(NSDictionary *)attributes;
- (id)initWithAttributes:(NSDictionary *)attributes
                 options:(BackboneOptions)options;
- (id)initWithAttributes:(NSDictionary *)attributes
              collection:(BackboneCollection *)collection;
- (id)initWithAttributes:(NSDictionary *)attributes
              collection:(BackboneCollection *)collection
                 options:(BackboneOptions)options;

- (NSDictionary *)toJSON;

- (id)get:(NSString *)attribute;

- (BOOL)has:(NSString *)attribute;

- (BOOL)set:(NSString *)attribute value:(id)value;
- (BOOL)set:(NSString *)attribute
      value:(id)value
    options:(BackboneOptions)options;
- (BOOL)set:(NSString *)attribute
      value:(id)value
    options:(BackboneOptions)options
errorCallback:(BackboneErrorBlock)errorCallback;

- (BOOL)set:(NSDictionary *)attributes;
- (BOOL)set:(NSDictionary *)attributes options:(BackboneOptions)options;
- (BOOL)set:(NSDictionary *)attributes
    options:(BackboneOptions)options
errorCallback:(BackboneErrorBlock)errorCallback;

- (BOOL)unset:(NSString *)attribute;
- (BOOL)unset:(NSString *)attribute options:(BackboneOptions)options;
- (BOOL)unset:(NSString *)attribute
      options:(BackboneOptions)options
errorCallback:(BackboneErrorBlock)errorCallback;

- (BOOL)clear;
- (BOOL)clearWithErrorCallback:(BackboneErrorBlock)errorCallback;
- (BOOL)clearWithOptions:(BackboneOptions)options
           errorCallback:(BackboneErrorBlock)errorCallback;

- (void)fetch;
- (void)fetchWithOptions:(BackboneOptions)options;
- (void)fetchWithOptions:(BackboneOptions)options
         successCallback:(BackboneSyncSuccessBlock)successCallback
           errorCallback:(BackboneErrorBlock)errorCallback;

- (BOOL)save;
- (BOOL)save:(NSDictionary *)attributes;
- (BOOL)save:(NSDictionary *)attributes options:(BackboneOptions)options;
- (BOOL)saveWithOptions:(BackboneOptions)options;
- (BOOL)saveWithOptions:(BackboneOptions)options
        successCallback:(BackboneSyncSuccessBlock)successCallback
          errorCallback:(BackboneErrorBlock)errorCallback;
- (BOOL)save:(NSDictionary *)attributes
     options:(BackboneOptions)options
successCallback:(BackboneSyncSuccessBlock)successCallback
errorCallback:(BackboneSyncSuccessBlock)errorCallback;

- (BOOL)destroy;
- (BOOL)destroyWithOptions:(BackboneOptions)options
           successCallback:(BackboneSyncSuccessBlock)successCallback
             errorCallback:(BackboneErrorBlock)errorCallback;

- (BOOL)isValid;

- (NSDictionary *)parse:(NSDictionary *)response;

- (id)clone;

- (BOOL)isNew;

- (void)change;
- (void)change:(NSArray *)changes;
- (void)change:(NSArray *)changes options:(BackboneOptions)options;

- (BOOL)hasChanged;
- (BOOL)hasChanged:(NSString *)attribute;

- (NSDictionary *)changedAttributes:(NSDictionary *)diff;

- (id)previous:(NSString *)attribute;

@end