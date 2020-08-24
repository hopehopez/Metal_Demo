//
//  MyRender.h
//  002_Triangle
//
//  Created by zsq on 2020/8/24.
//  Copyright © 2020 zsq. All rights reserved.
//

//导入MetalKit工具包
@import MetalKit;

NS_ASSUME_NONNULL_BEGIN

@interface MyRender : NSObject<MTKViewDelegate>
- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView;

@end

NS_ASSUME_NONNULL_END
