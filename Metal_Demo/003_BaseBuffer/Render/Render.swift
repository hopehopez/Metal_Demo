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
        mtkView.colorPixelFormat = .rgba8Unorm_srgb
        
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
        vertexBuffer = device?.makeBuffer(bytes: verteices, length: MemoryLayout<ZVertex>.size*verteices.count, options: .cpuCacheModeWriteCombined)
        
        numVertices = verteices.count
        
        //6.创建命令队列
        commandQueue = device?.makeCommandQueue()
    }
    
    func generateVertexData() -> [ZVertex]{
        var quadVertices = [ZVertex(position: [-20, 20], color: [1, 0, 0, 1]),
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
        
        //数据大小 = 单个四边形大小 * 行 * 列
        let dataSize = MemoryLayout<ZVertex>.size * NUM_VERTICES_PER_QUAD * NUM_COLUMNS * NUM_ROWS
        
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
                    let newVertex = ZVertex(position: vertex.position, color: vertex.color)
                    vertices.append(newVertex)
                    vertex.position += upperLeftPosition
                }

            }
        }
        return vertices
    }
    
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // 保存可绘制的大小，因为当我们绘制时，我们将把这些值传递给顶点着色器
        viewportSize.x = UInt32(size.width)
        viewportSize.y = UInt32(size.height)
        
    }
    
    func draw(in view: MTKView) {
    }
}
