//
//  Backbone.h
//  Backbone
//
//  Created by Edmond Leung on 5/10/12.
//  Copyright (c) 2012. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BackboneTypes.h"
#import "BackboneEvents.h"
#import "BackboneModel.h"
#import "BackboneCollection.h"

@interface Backbone : NSObject {
}

+ (void)emulateHTTP;
+ (void)emulateJSON;

+ (void)stopEmulatingHTTP;
+ (void)stopEmulatingJSON;

+ (void)sync:(id)model
      method:(BackboneSyncCRUDMethod)method 
successCallback:(BackboneSyncSuccessBlock)successCallback
errorCallback:(BackboneErrorBlock)errorCallback;

@end
