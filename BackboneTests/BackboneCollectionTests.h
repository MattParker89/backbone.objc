//
//  BackboneCollectionTests.h
//  Backbone
//
//  Created by Edmond Leung on 7/10/12.
//  Copyright (c) 2012. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

@class BackboneModel;
@class BackboneCollection;

@interface BackboneCollectionTests : SenTestCase {
  BackboneModel *a_;
  BackboneModel *b_;
  BackboneModel *c_;
  BackboneModel *d_;
  BackboneModel *e_;
  BackboneCollection *col_;
  BackboneCollection *otherCol_;
}

@end
