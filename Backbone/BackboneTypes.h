//
//  BackboneTypes.h
//  Backbone
//
//  Created by Edmond Leung on 5/15/12.
//  Copyright (c) 2012. All rights reserved.
//

#ifndef Backbone_BackboneTypes_h
#define Backbone_BackboneTypes_h

@class BackboneModel;
@class BackboneCollection;

typedef void (^BackboneErrorBlock)(id subject, NSError *error);
typedef void (^BackboneEventBlock)(NSNotification *notification);
typedef void (^BackboneSyncSuccessBlock)(id modelOrCollection, id response);

typedef enum {
  BackboneSyncCRUDMethodCreate,
  BackboneSyncCRUDMethodUpdate,
  BackboneSyncCRUDMethodDelete,
  BackboneSyncCRUDMethodRead
} BackboneSyncCRUDMethod;

typedef enum {
  BackboneSetSilently = 1 << 0,
  BackboneParseAttributes = 2 << 0,
  BackboneSyncWait = 3 << 0,
  BackboneAddToCollection = 4 << 0
} BackboneOptions;

#endif
