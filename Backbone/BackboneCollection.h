//
//  BackboneCollection.h
//  Backbone
//
//  Created by Edmond Leung on 6/28/12.
//  Copyright (c) 2012. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BackboneTypes.h"
#import "BackboneEvents.h"

@protocol BackboneCollection <NSObject>

@optional

+ (void)sync:(BackboneCollection *)collection
      method:(BackboneSyncCRUDMethod)method 
successCallback:(BackboneSyncSuccessBlock)successCallback
errorCallback:(BackboneErrorBlock)errorCallback;

@end

@interface BackboneCollection : NSMutableArray
  <BackboneCollection, BackboneEventsMixin, NSFastEnumeration> {
 @private
  Class model_;
  NSMutableArray *models_;
  NSComparator comparator_;
  NSString *url_;
  NSMutableDictionary *byCid_;
  NSMutableDictionary *byId_;
  BackboneEventBlock onModelEvent_;
}

@property (nonatomic, assign) Class model;
@property (nonatomic, readonly) NSMutableArray *models;
@property (nonatomic, copy) NSComparator comparator;
@property (nonatomic, copy) NSString *url;

- (id)initWithModels:(NSArray *)models;
- (id)initWithModel:(Class)model models:(NSArray *)models;
- (id)initWithModel:(Class)model
             models:(NSArray *)models
            options:(BackboneOptions)options;

- (NSDictionary *)toJSON;

- (void)add:(id)modelOrAttributes;
- (void)add:(id)modelOrAttributes options:(BackboneOptions)options;
- (void)add:(id)modelOrAttributes at:(NSUInteger)at;
- (void)add:(id)modelOrAttributes
    options:(BackboneOptions)options
errorCallback:(BackboneErrorBlock)errorCallback;
- (void)add:(id)modelOrAttributes
         at:(NSUInteger)at 
errorCallback:(BackboneErrorBlock)errorCallback;
- (void)addModels:(NSArray *)models;
- (void)addModels:(NSArray *)models options:(BackboneOptions)options;
- (void)addModels:(NSArray *)models at:(NSUInteger)at;
- (void)addModels:(NSArray *)models
          options:(BackboneOptions)options
    errorCallback:(BackboneErrorBlock)errorCallback;
- (void)addModels:(NSArray *)models
               at:(NSUInteger)at
    errorCallback:(BackboneErrorBlock)errorCallback;
- (void)addModels:(NSArray *)models
               at:(NSUInteger)at
          options:(BackboneOptions)options;
- (void)addModels:(NSArray *)models
               at:(NSUInteger)at
          options:(BackboneOptions)options
    errorCallback:(BackboneErrorBlock)errorCallback;

- (void)remove:(id)modelOrId;
- (void)remove:(id)modelOrId options:(BackboneOptions)options;
- (void)removeModels:(NSArray *)models;
- (void)removeModels:(NSArray *)models options:(BackboneOptions)options;

- (BackboneModel *)push:(id)modelOrAttributes;
- (BackboneModel *)push:(id)modelOrAttributes
                options:(BackboneOptions)options;
- (BackboneModel *)push:(id)modelOrAttributes
                options:(BackboneOptions)options
          errorCallback:(BackboneErrorBlock)errorCallback;

- (BackboneModel *)pop;
- (BackboneModel *)popWithOptions:(BackboneOptions)options;

- (BackboneModel *)unshift:(id)modelOrAttributes;
- (BackboneModel *)unshift:(id)modelOrAttributes
                   options:(BackboneOptions)options;
- (BackboneModel *)unshift:(id)modelOrAttributes
                   options:(BackboneOptions)options
             errorCallback:(BackboneErrorBlock)errorCallback;

- (BackboneModel *)shift;
- (BackboneModel *)shiftWithOptions:(BackboneOptions)options;

- (BackboneModel *)getByCid:(id)cidOrModel;

- (BackboneModel *)get:(id)idOrModel;

- (BackboneModel *)at:(NSUInteger)index;

- (NSArray *)where:(NSDictionary *)attributes;

- (void)sort;
- (void)sortWithOptions:(BackboneOptions)options;

- (NSArray *)pluck:(NSString *)attribute;

- (void)reset:(NSArray *)models;
- (void)reset:(NSArray *)models options:(BackboneOptions)options;

- (void)fetch;
- (void)fetchWithOptions:(BackboneOptions)options;
- (void)fetchWithSuccessCallback:(BackboneSyncSuccessBlock)successCallback
                   errorCallback:(BackboneErrorBlock)errorCallback
                         options:(BackboneOptions)options;

- (BackboneModel *)create:(id)modelOrAttributes;
- (BackboneModel *)create:(id)modelOrAttributes
                  options:(BackboneOptions)options;
- (BackboneModel *)create:(id)modelOrAttributes 
          successCallback:(BackboneSyncSuccessBlock)successCallback
            errorCallback:(BackboneErrorBlock)errorCallback
                  options:(BackboneOptions)options;

- (NSArray *)parse:(NSArray *)response;

@end
