//
//  BackboneHistory.h
//  Backbone
//
//  Created by Edmond Leung on 7/19/12.
//  Copyright (c) 2012. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BackboneTypes.h"
#import "BackboneEvents.h"

@interface BackboneHistory : NSObject <BackboneEventsMixin> {
 @private
  NSMutableArray *handlers_;
  NSMutableArray *history_;
}

- (void)route:(NSRegularExpression *)route
   toCallback:(void (^)(NSString *url))callback;

- (void)navigate:(NSString *)url options:(BackboneHistoryOptions)options;

@end
