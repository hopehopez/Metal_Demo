//
//  Render.swift
//  002_Triangle
//
//  Created by zsq on 2020/8/21.
//  Copyright © 2020 zsq. All rights reserved.
//

import MetalKit

class Render: NSObject, MTKViewDelegate {
    //我们用来渲染的设备(又名GPU)
var device: MTLDevice?
    //命令队列,从命令缓存区获取
var commandQueue: MTLCommandQueue?
     /// 我们的渲染管道有顶点着色器和片元着色器 它们存储在.metal shader 文件中
    var pipelineState: MTLRenderPipelineState!
    //当前视图大小,这样我们才可以在渲染通道使用这个视图
    var viewportSize: vector_int2! = vector_int2(0, 0)
    convenience init(mtkView: MTKView) {
        self.init()
        
        //1.获取GPU 设备
        device = mtkView.device
        
        //2.在项目中加载所有的(.metal)着色器文件
        // 从bundle中获取.metal文件
        let defaultLibrary = device?.makeDefaultLibrary()
        //从库中加载顶点函数
        let vertexFunction = defaultLibrary?.makeFunction(name: "vertexShader")
        //从库中加载片元函数
        let fragmentFunction = defaultLibrary?.makeFunction(name: "fragmentShader")
        
        //3.配置用于创建管道状态的管道
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        //管道名称
        pipelineStateDescriptor.label = "Simple Pipeline"
        //可编程函数,用于处理渲染过程中的各个顶点
        pipelineStateDescriptor.vertexFunction = vertexFunction
        //可编程函数,用于处理渲染过程中各个片段/片元
        pipelineStateDescriptor.fragmentFunction = fragmentFunction
        //一组存储颜色数据的组件
        pipelineStateDescriptor.colorAttachments[0].pixelFormat  = mtkView.colorPixelFormat
        
        //4.同步创建并返回渲染管线状态对象
        do {
            pipelineState = try device?.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
            
        } catch {
            print("Failed to created pipeline state, error %@", error.localizedDescription)
            
        }
        
        //5.创建命令队列
        commandQueue = device!.makeCommandQueue()
    }
    
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // 保存可绘制的大小，因为当我们绘制时，我们将把这些值传递给顶点着色器
        viewportSize.x = Int32(size.width)
        viewportSize.y = Int32(size.height)
        
    }
    
    func draw(in view: MTKView) {
        
        //1. 顶点数据/颜色数据
        let triangleVertices = [Vertex(position: vector_float4(0.5, -0.25, 0.0, 1.0), color:                              vector_float4(1, 0, 0, 1)),
                                Vertex(position: vector_float4(-0.5, -0.25, 0.0, 1.0), color: vector_float4(0, 1, 0, 1)),
                                Vertex(position: vector_float4(0.0, -0.25, 0.0, 1.0), color: vector_float4(0, 0, 1, 1))
                                ]
         
        //2.为当前渲染的每个渲染传递创建一个新的命令缓冲区
        let commandBuffer = commandQueue?.makeCommandBuffer()
        commandBuffer?.label = "MyCommand"
        
        //3. MTLRenderPassDescriptor:一组渲染目标，用作渲染通道生成的像素的输出目标。
        if let renderPassDescriptor = view.currentRenderPassDescriptor {
            
            //4.创建渲染命令编码器,这样我们才可以渲染到something
            let renderDecoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
            //渲染器名称
            renderDecoder?.label = "MyRenderEncoder"
            
            //5.设置我们绘制的可绘制区域
            /*
            typedef struct {
                double originX, originY, width, height, znear, zfar;
            } MTLViewport;
             */
            //视口指定Metal渲染内容的drawable区域。 视口是具有x和y偏移，宽度和高度以及近和远平面的3D区域
            //为管道分配自定义视口需要通过调用setViewport：方法将MTLViewport结构编码为渲染命令编码器。 如果未指定视口，Metal会设置一个默认视口，其大小与用于创建渲染命令编码器的drawable相同。
            let viewPort = MTLViewport(originX: 0.0, originY: 0.0, width: Double(viewportSize.x), height: Double(viewportSize.y), znear: -1.0, zfar: 1.0)
            
            renderDecoder?.setViewport(viewPort)
            
            //6.设置当前渲染管道状态对象
            renderDecoder?.setRenderPipelineState(pipelineState)
            
            //7.从应用程序OC 代码 中发送数据给Metal 顶点着色器 函数
            //顶点数据+颜色数据
            //   1) 指向要传递给着色器的内存的指针
            //   2) 我们想要传递的数据的内存大小
            //   3)一个整数索引，它对应于我们的“vertexShader”函数中的缓冲区属性限定符的索引。
            renderDecoder?.setVertexBytes(triangleVertices, length:  MemoryLayout<Vertex>.size*triangleVertices.count, index:
                Int(VertexInputIndexVertices.rawValue))
            
            //viewPortSize 数据
            //1) 发送到顶点着色函数中,视图大小
            //2) 视图大小内存空间大小
            //3) 对应的索引
            renderDecoder?.setVertexBytes(&viewportSize, length: MemoryLayout.size(ofValue: viewportSize), index: Int(VertexInputIndexViewportSize.rawValue))
            
            
            //8.画出三角形的3个顶点
                   // @method drawPrimitives:vertexStart:vertexCount:
                   //@brief 在不使用索引列表的情况下,绘制图元
                   //@param 绘制图形组装的基元类型
                   //@param 从哪个位置数据开始绘制,一般为0
                   //@param 每个图元的顶点个数,绘制的图型顶点数量
                   /*
                    MTLPrimitiveTypePoint = 0, 点
                    MTLPrimitiveTypeLine = 1, 线段
                    MTLPrimitiveTypeLineStrip = 2, 线环
                    MTLPrimitiveTypeTriangle = 3,  三角形
                    MTLPrimitiveTypeTriangleStrip = 4, 三角型扇
                    */
            
            renderDecoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
            
            //9.表示已该编码器生成的命令都已完成,并且从NTLCommandBuffer中分离
            renderDecoder?.endEncoding()
            
            //10.一旦框架缓冲区完成，使用当前可绘制的进度表
            commandBuffer?.present(view.currentDrawable!)
            
            
        }
        
        //11.最后,在这里完成渲染并将命令缓冲区推送到GPU
        commandBuffer?.commit()
    }
}
