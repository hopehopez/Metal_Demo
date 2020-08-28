//
//  Render.swift
//  003_BaseBuffer
//
//  Created by zsq on 2020/8/28.
//  Copyright © 2020 zsq. All rights reserved.
//

import MetalKit

class Render: NSObject, MTKViewDelegate {
    //渲染的设备(GPU)
    var device: MTLDevice?
    //命令队列,从命令缓存区获取
    var commandQueue: MTLCommandQueue?
    //渲染管道:顶点着色器/片元着色器,存储于.metal shader文件中
    var pipelineState: MTLRenderPipelineState!
    //当前视图大小,这样我们才能在渲染通道中使用此视图
    var viewportSize = vector_uint2(100, 100)
    
    
    convenience init(mtkView: MTKView) {
        self.init()
        
        device = mtkView.device
        
        loadMetal(mtkView: mtkView)
    }
    
    func loadMetal(mtkView: MTKView) {
        //1.设置绘制纹理的像素格式
        mtkView.colorPixelFormat = .rgba8Unorm_srgb
        
        
        
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // 保存可绘制的大小，因为当我们绘制时，我们将把这些值传递给顶点着色器
        viewportSize.x = UInt32(size.width)
        viewportSize.y = UInt32(size.height)
        
    }
    
    func draw(in view: MTKView) {
    }
}
