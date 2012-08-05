//
//  Backbone.m
//  Backbone
//
//  Created by Edmond Leung on 5/10/12.
//  Copyright (c) 2012. All rights reserved.
//

#import "Backbone.h"
#import "ARCHelper.h"
#import "NSDictionary+Backbone.h"
#import "NSArray+Backbone.h"

@implementation Backbone

static BackboneHistory *history__;
static BOOL emulateHTTP__ = NO, emulateJSON__ = NO;

+ (BackboneHistory *)history {
  if (history__) return history__;
  return history__ = [[BackboneHistory alloc] init];
}

+ (void)emulateHTTP { emulateHTTP__ = YES; }
+ (void)emulateJSON { emulateJSON__ = YES; }

+ (void)stopEmulatingHTTP { emulateHTTP__ = NO; }
+ (void)stopEmulatingJSON { emulateJSON__= NO; }

+ (void)sync:(id)model
      method:(BackboneSyncCRUDMethod)method 
successCallback:(BackboneSyncSuccessBlock)successCallback
errorCallback:(BackboneErrorBlock)errorCallback {
  NSString *httpMethod, *contentType;
  NSMutableURLRequest *request;
  NSMutableDictionary *data = nil;
  
  // Translate CRUD method to HTTP equivalient.
  httpMethod = [[NSArray arrayWithObjects:
                 @"POST", @"PUT", @"DELETE", @"GET", nil] objectAtIndex:method];
  
  // Create the request with the default content type.
  request = [NSMutableURLRequest
             requestWithURL:[NSURL URLWithString:(id)[model url]]];
  request.HTTPMethod = httpMethod;
  contentType = @"application/x-www-form-urlencoded";
  
  // Ensure that we have the appropriate request data.
  if (model && (method == BackboneSyncCRUDMethodCreate ||
                            method == BackboneSyncCRUDMethodUpdate)) {
    contentType = @"application/json";
    data = [NSMutableDictionary
            dictionaryWithDictionary:[model toJSON]];
  }
  
  // For older servers, emulate JSON by encoding the request into an HTML-form.
  if (emulateJSON__) {
    contentType = @"application/x-www-form-urlencoded";
    data = data ? 
      [NSMutableDictionary dictionaryWithObject:data forKey:@"model"] : 
      [NSMutableDictionary dictionary];
  }
  
  // For older servers, emulate HTTP by mimicking the HTTP method with '_method'
  // and an 'X-HTTP-Method-Override' header.
  if (emulateHTTP__) {
    if (([httpMethod isEqualToString:@"PUT"] || 
         [httpMethod isEqualToString:@"DELETE"])) {
      if (emulateJSON__) [data setObject:httpMethod forKey:@"_method"];
      [request setHTTPMethod:@"POST"];
      [request setValue:httpMethod
               forHTTPHeaderField:@"X-HTTP-Method-Override"];
    }
  }
  
  // Process data for use as request body.
  if (data) {
    if (emulateJSON__) {
      request.HTTPBody = [[data encodedURL]
                          dataUsingEncoding:NSUTF8StringEncoding];
    } else {
      request.HTTPBody = [NSJSONSerialization dataWithJSONObject:data
                                                         options:0
                                                           error:nil];
    }
  }
  
  [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
  [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
  [request setValue:[NSString stringWithFormat:@"%d", request.HTTPBody.length]
 forHTTPHeaderField:@"Content-Length"];
  
  // Make the request.
  [NSURLConnection
   sendAsynchronousRequest:request
   queue:[NSOperationQueue mainQueue]
   completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
     if (error && errorCallback) {
       // Wrap an optional error callback with a fallback error event.
       if (errorCallback) {
         errorCallback(model, error);
       } else {
         [model trigger:@"error" arguments:model, error, nil];
       }
     } else if (successCallback) {
       successCallback(model,
                       [NSJSONSerialization JSONObjectWithData:data
                                                       options:0
                                                         error:nil]);
     }
   }];
}

@end
