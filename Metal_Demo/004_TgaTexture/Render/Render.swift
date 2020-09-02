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
        let vertexFunction = defaultLibiary?.makeFunction(name: "vertexShader")
        let fragmentFunction = defaultLibiary?.makeFunction(name: "fragmentShader")
        
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
        //1.获取tag的路径
        guard let imageFileLocation = Bundle.main.url(forResource: "Image", withExtension: "tga") else {
            return
        }
        
        //将tag文件->ZImage对象
        guard let image = ZImage(tgaFileAtLocation: imageFileLocation) else {
            print("Failed to create the image from: \(imageFileLocation.absoluteString)")
            return
        }
        
        //2.创建纹理描述对象
        let textureDescriptor = MTLTextureDescriptor()
         //表示每个像素有蓝色,绿色,红色和alpha通道.其中每个通道都是8位无符号归一化的值.(即0映射成0,255映射成1);
        textureDescriptor.pixelFormat = MTLPixelFormat.bgra8Unorm
        //设置纹理的像素尺寸
        textureDescriptor.width = Int(image.width)
        textureDescriptor.height = Int(image.height)
        
        //使用描述符从设备中创建纹理
        texture = device?.makeTexture(descriptor: textureDescriptor)
        
        //计算图像每行的字节数
        let bytesPerRow = image.width * 4
        
        /*
            typedef struct
            {
            MTLOrigin origin; //开始位置x,y,z
            MTLSize   size; //尺寸width,height,depth
            } MTLRegion;
            */
           //MLRegion结构用于标识纹理的特定区域。 demo使用图像数据填充整个纹理；因此，覆盖整个纹理的像素区域等于纹理的尺寸。
           //3. 创建MTLRegion 结构体
        let region = MTLRegion(origin:MTLOriginMake(0, 0, 0), size: MTLSizeMake(Int(image.width), Int(image.height), 1))
        
        
        //4.复制图片数据到texture
        texture?.replace(region: region, mipmapLevel: 0, withBytes: [UInt8](image.data), bytesPerRow: Int(bytesPerRow))
        
    }
    
    //每当视图改变方向或调整大小时调用
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // 保存可绘制的大小，因为当我们绘制时，我们将把这些值传递给顶点着色器
        viewportSize.x = Float(size.width)
        viewportSize.y = Float(size.height)
        
    }
    
    //每当视图需要渲染帧时调用
    func draw(in view: MTKView) {
        //1.为当前渲染的每个渲染传递创建一个新的命令缓冲区
        let commandBuffer = commandQueue?.makeCommandBuffer()
        //指定缓存区名称
        commandBuffer?.label = "MyCommand";
        
        //2. currentRenderPassDescriptor 描述符包含currentDrawable's 的纹理、视图的深度、模板和 sample 缓冲区和清晰的值。
        if let renderPassDescriptor = view.currentRenderPassDescriptor {
            //3.创建渲染命令编码器,这样我们才可以渲染到something
            let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
            renderEncoder?.label = "MyRenderEncoder"
            
            //4.设置我们绘制的可绘制区域
                   /*
                    typedef struct {
                    double originX, originY, width, height, znear, zfar;
                    } MTLViewport;
                    */
            renderEncoder?.setViewport(MTLViewport(originX: 0, originY: 0, width: Double(viewportSize.x), height: Double(viewportSize.y), znear: -1.0, zfar: 1.0))
            
            //5.设置渲染管道
            renderEncoder?.setRenderPipelineState(pipelineState)
            
            //6.加载数据
            renderEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: Int(ZVertexInputVertices.rawValue))
            renderEncoder?.setVertexBytes(&viewportSize, length: MemoryLayout<MTLViewport>.size, index: Int(ZVertexInputViewportSize.rawValue))
            
            //7.设置纹理对象
            renderEncoder?.setFragmentTexture(texture, index: Int(ZTextureIndexBaseColor.rawValue))
            
             //8.绘制
            renderEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: numVertices)
            
             //9.表示已该编码器生成的命令都已完成,并且从NTLCommandBuffer中分离
            renderEncoder?.endEncoding()
            
             //10.一旦框架缓冲区完成，使用当前可绘制的进度表
            commandBuffer?.present(view.currentDrawable!)
            
        }
        //11.最后,在这里完成渲染并将命令缓冲区推送到GPU
        commandBuffer?.commit()
    }
        
}
