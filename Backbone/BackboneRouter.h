//
//  BackboneRouter.h
//  Backbone
//
//  Created by Edmond Leung on 7/20/12.
//  Copyright (c) 2012. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BackboneTypes.h"
#import "BackboneEvents.h"

@interface BackboneRouter : NSObject <BackboneEventsMixin>

- (void)route:(id)route to:(SEL)selector;
- (void)route:(id)route to:(SEL)selector named:(NSString *)name;

- (void)navigate:(NSString *)url options:(BackboneHistoryOptions)options;

@end
