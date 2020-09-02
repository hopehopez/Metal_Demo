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
    //顶点缓存区
    var vertexBuffer: MTLBuffer?
    //顶点个数
    var numVertices = 0
    
    convenience init(mtkView: MTKView) {
        self.init()
        
        device = mtkView.device
        
        loadMetal(mtkView: mtkView)
    }
    
    func loadMetal(mtkView: MTKView) {
        //1.设置绘制纹理的像素格式
        mtkView.colorPixelFormat = .bgra8Unorm_srgb
        
        //2.从项目中加载所以的.metal着色器文件
        let defaultLibrary = device?.makeDefaultLibrary()
        let vertexFunction = defaultLibrary?.makeFunction(name: "vertexShader")
        let fragmentFunction = defaultLibrary?.makeFunction(name: "fragmentShader")
        
        //3.配置用于创建管道状态的管道
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.label = "imple Pipeline"
        pipelineStateDescriptor.vertexFunction = vertexFunction
        pipelineStateDescriptor.fragmentFunction = fragmentFunction
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        
        //4.同步创建并返回渲染管线对象
        pipelineState = try! device?.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        
         //5.获取顶点数据
        let verteices = generateVertexData()
        //创建一个vertex buffer,可以由GPU来读取
        vertexBuffer = device?.makeBuffer(bytes: verteices, length: MemoryLayout<ZVertex>.size*verteices.count, options: [])
        
        numVertices = verteices.count
        
        //6.创建命令队列
        commandQueue = device?.makeCommandQueue()
    }
    
    func generateVertexData() -> [ZVertex]{
        let quadVertices = [ZVertex(position: [-20, 20], color: [1, 0, 0, 1]),
                            ZVertex(position: [20, 20], color: [1, 0, 0, 1]),
                            ZVertex(position: [-20, -20], color: [1, 0, 0, 1]),
                            
                            ZVertex(position: [20, -20], color: [0, 0, 1, 1]),
                            ZVertex(position: [-20, -20], color: [0, 0, 1, 1]),
                            ZVertex(position: [20, 20], color: [0, 0, 1, 1]),
        ]
        
        //行/列 数量
        let NUM_COLUMNS = 25
        let NUM_ROWS = 15
        
        //顶点个数
        let NUM_VERTICES_PER_QUAD = quadVertices.count
        
         //四边形间距
        let QUAD_SPACING:Float = 50.0
        
        
        //2. 开辟空间
        var vertices = [ZVertex]()
        
        //3.获取顶点坐标(循环计算)
        for row in 0..<NUM_ROWS {
            for column in 0..<NUM_COLUMNS {
                //左上角的位置 注意坐标系基于2D笛卡尔坐标系,中心点(0,0),所以会出现负数位置
                let x = (Float(-NUM_COLUMNS)/2 + Float(column)) * QUAD_SPACING + QUAD_SPACING/2.0
                let y = (Float(-NUM_ROWS)/2 + Float(row)) * QUAD_SPACING + QUAD_SPACING/2.0
                let upperLeftPosition = vector2(x, y)
                
                for index in 0..<NUM_VERTICES_PER_QUAD {
                    var vertex = quadVertices[index]
                    vertex.position += upperLeftPosition
                    let newVertex = ZVertex(position: vertex.position, color: vertex.color)
                    vertices.append(newVertex)
                    print(vertex.position)
                }

            }
        }
        return vertices
    }
    
    //每当视图改变方向或调整大小时调用
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // 保存可绘制的大小，因为当我们绘制时，我们将把这些值传递给顶点着色器
        viewportSize.x = UInt32(size.width)
        viewportSize.y = UInt32(size.height)
        
    }
    
    //每当视图需要渲染帧时调用
    func draw(in view: MTKView) {
        
        //1.为当前渲染的每个渲染传递创建一个新的命令缓冲区
        let commandBuffer = commandQueue?.makeCommandBuffer()
        //指定缓存区名称
        commandBuffer?.label = "MyCommandBuffer"
        
        //2. MTLRenderPassDescriptor:一组渲染目标，用作渲染通道生成的像素的输出目标。
        if let renderPassDescriptor = view.currentRenderPassDescriptor {
            
            //创建渲染命令编码器,这样我们才可以渲染到something
            let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
            renderEncoder?.label = "MyRenderEncoder"
            
            //3.设置我们绘制的可绘制区域
            renderEncoder?.setViewport(MTLViewport(originX: 0, originY: 0, width: Double(viewportSize.x), height: Double(viewportSize.y), znear: -1.0, zfar: 1.0))
            
            //4. 设置渲染管道
            renderEncoder?.setRenderPipelineState(pipelineState)
            
            //5.我们调用-[MTLRenderCommandEncoder setVertexBuffer:offset:atIndex:] 为了从我们的OC代码找发送数据预加载的MTLBuffer 到我们的Metal 顶点着色函数中
            /* 这个调用有3个参数
                1) buffer - 包含需要传递数据的缓冲对象
                2) offset - 它们从缓冲器的开头字节偏移，指示“顶点指针”指向什么。在这种情况下，我们通过0，所以数据一开始就被传递下来.偏移量
                3) index - 一个整数索引，对应于我们的“vertexShader”函数中的缓冲区属性限定符的索引。注意，此参数与 -[MTLRenderCommandEncoder setVertexBytes:length:atIndex:] “索引”参数相同。
             */
            
            //将_vertexBuffer 设置到顶点缓存区中
            renderEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: Int(ZVertexInputIndexVertices.rawValue))
            
             //将 _viewportSize 设置到顶点缓存区绑定点设置数据
            renderEncoder?.setVertexBytes(&viewportSize, length: MemoryLayout<MTLViewport>.size, index: Int(ZVertexInputIndexViewportSize.rawValue))
            
            //6.开始绘图
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
            renderEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: numVertices)
            
            //7表示已该编码器生成的命令都已完成,并且从NTLCommandBuffer中分离
            renderEncoder?.endEncoding()
            
            //8.一旦框架缓冲区完成，使用当前可绘制的进度表
            commandBuffer?.present(view.currentDrawable!)
            
        }
        commandBuffer?.commit()
    }
}
