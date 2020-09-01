//
//  Render.swift
//  004_TgaTexture
//
//  Created by zsq on 2020/9/1.
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
    var viewportSize = vector_float2(100.0, 100.0)
    //顶点缓存区
    var vertexBuffer: MTLBuffer?
    //顶点个数
    var numVertices = 0
    //纹理对象
    var texture: MTLTexture?
    
    var mtkView: MTKView!
    
    convenience init(mtkView: MTKView) {
        self.init()
        
        //1.获取GPU设备
        device = mtkView.device
        self.mtkView = mtkView
        
        //2.设置顶点相关操作
        setupVertex()
        
        //3.设置渲染管道相关操作
        setupPipeline()
        
        //4.加载纹理TGA 文件
        setupTexture()
        
    }
    
    func setupVertex() {
        //1.根据顶点/纹理坐标建立一个MTLBuffer
        let quadVertices = [ZVertex(position: [250, -250], textureCoordinate: [1.0, 0.0]),
                            ZVertex(position: [-250, -250], textureCoordinate: [0.0, 0.0]),
                            ZVertex(position: [-250, 250], textureCoordinate: [0.0, 1.0]),
                            
                            ZVertex(position: [250, -250], textureCoordinate: [1.0, 0.0]),
                            ZVertex(position: [-250, 250], textureCoordinate: [0.0, 1.0]),
                            ZVertex(position: [250, 250], textureCoordinate: [1.0, 1.0]),
        ]
        
        //2.创建我们的顶点缓冲区，并用我们的Qualsits数组初始化它
        vertexBuffer = device?.makeBuffer(bytes: quadVertices, length: MemoryLayout<ZVertex>.size*6, options: .storageModeShared)
        
        //顶点个数
        numVertices = 6
    }
    
    func setupPipeline() {
        //1.创建我们的渲染通道
        let defaultLibiary = device?.makeDefaultLibrary()
        let vertexFunction = defaultLibiary?.makeFunction(name: "vertexFunction")
        let fragmentFunction = defaultLibiary?.makeFunction(name: "fragmentFunction")
        
        //2.配置用于创建管道状态的管道
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.label = "Texturing Pipeline"
        pipelineStateDescriptor.vertexFunction = vertexFunction
        pipelineStateDescriptor.fragmentFunction = fragmentFunction
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        
        //3.同步创建并返回渲染管线对象
        pipelineState = try! device?.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        
        //4.使用_device创建commandQueue
        commandQueue = device?.makeCommandQueue()
        
    }
    
    func setupTexture() {
        
    }
    
    //每当视图改变方向或调整大小时调用
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // 保存可绘制的大小，因为当我们绘制时，我们将把这些值传递给顶点着色器
        viewportSize.x = Float(size.width)
        viewportSize.y = Float(size.height)
        
    }
    
    //每当视图需要渲染帧时调用
    func draw(in view: MTKView) {
    }
        
}
