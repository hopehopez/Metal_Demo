//
//  ViewController.swift
//  006_RenderMOV
//
//  Created by zsq on 2020/9/8.
//  Copyright © 2020 zsq. All rights reserved.
//

import UIKit
import MetalKit
import AVFoundation

class ViewController: UIViewController, MTKViewDelegate {
    //MTKView
    var mtkView: MTKView!
    //ZAssetReader 读取MOV 文件中视频数据
    var reader: ZAssetReader!
    //高速纹理读取缓存区.
    var textureCache: CVMetalTextureCache!
    //viewportSize 视口大小
    var viewportSize: vector_int2!
    //渲染管道
    var pipelineState: MTLRenderPipelineState!
    //命令队列
    var commandQueue: MTLCommandQueue!
    //纹理
    var texture: MTLTexture!
    //顶点缓存区
    var vertices: MTLBuffer!
    //YUV->RGB转换矩阵
    var convertMatrix: MTLBuffer!
    //顶点个数
    var numVertices: Int!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        setupMTKView()
        setupAssetReader()
        setupPipeline()
        setupVertex()
        setupMatrix()
        
    }
    
    //1.MTKView 设置
    func setupMTKView() {
        //1.初始化mtkView
        mtkView = MTKView(frame: view.bounds)
        // 获取默认的device
        mtkView.device = MTLCreateSystemDefaultDevice()
        //设置self.view = self.mtkView;
        view = mtkView
        //设置代理
        mtkView.delegate = self
        //获取视口size
        viewportSize = vector_int2(Int32(mtkView.drawableSize.width), Int32(mtkView.drawableSize.height))
        mtkView.preferredFramesPerSecond = 24
    }
    
    //2.ZAssetReader设置
    func setupAssetReader() {
        //1.视频文件路径
        guard let url = Bundle.main.url(forResource: "baozha", withExtension: "mp4") else {return}
        //        guard let url = Bundle.main.url(forResource: "kun2", withExtension: "mp4") else {return}
        
        //2.初始化ZAssetReader
        reader = ZAssetReader(url: url)
        
        //3._textureCache的创建(通过CoreVideo提供给CPU/GPU高速缓存通道读取纹理数据)
        CVMetalTextureCacheCreate(nil, nil, mtkView.device!, nil, &textureCache)
    }
    
    // 设置渲染管道
    func setupPipeline() {
        //1 获取.metal
        /*
         newDefaultLibrary: 默认一个metal 文件时,推荐使用
         newLibraryWithFile:error: 从Library 指定读取metal 文件
         newLibraryWithData:error: 从Data 中获取metal 文件
         */
        let defaultLibrary = mtkView.device?.makeDefaultLibrary()
        let vertexFunction = defaultLibrary?.makeFunction(name: "vertexShader")
        let fragmentFunction = defaultLibrary?.makeFunction(name: "fragmentShader")
        
        //2.渲染管道描述信息类
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexFunction
        pipelineStateDescriptor.fragmentFunction = fragmentFunction
        // 设置颜色格式
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        
        //3.初始化渲染管道根据渲染管道描述信息
        // 创建图形渲染管道，耗性能操作不宜频繁调用
        pipelineState = try! mtkView.device?.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        
        //4.CommandQueue是渲染指令队列，保证渲染指令有序地提交到GPU
        commandQueue = mtkView.device?.makeCommandQueue()
    }
    
    // 设置顶点
    func setupVertex() {
        //1.顶点坐标(x,y,z,w);纹理坐标(x,y)
        //注意: 为了让视频全屏铺满,所以顶点大小均设置[-1,1]
        let quadVertices = [
            ZVertex(position: [1.0, -1.0, 0.0, 1.0], textureCoordinate: [1.0, 1.0]),
            ZVertex(position: [-1.0, -1.0, 0.0, 1.0], textureCoordinate: [0.0, 1.0]),
            ZVertex(position: [-1.0, 1.0, 0.0, 1.0], textureCoordinate: [0.0, 0.0]),
            
            ZVertex(position: [1.0, -1.0, 0.0, 1.0], textureCoordinate: [1.0, 1.0]),
            ZVertex(position: [-1.0, 1.0, 0.0, 1.0], textureCoordinate: [0.0, 0.0]),
            ZVertex(position: [1.0, 1.0, 0.0, 1.0], textureCoordinate: [1.0, 0.0])]
        
        //2.创建顶点缓存区
        vertices = mtkView.device?.makeBuffer(bytes: quadVertices, length: MemoryLayout<ZVertex>.size*quadVertices.count, options: .storageModeShared)
        
        //3.计算顶点个数
        numVertices = quadVertices.count
        
    }
    
    // 设置YUV->RGB转换的矩阵
    func setupMatrix() {
        //1.转化矩阵
        // BT.601, which is the standard for SDTV.
        let kColorConversion601DefaultMatrix = matrix_float3x3(columns: (
            simd_float3(1.164,  1.164, 1.164),
            simd_float3(0.0, -0.392, 2.017),
            simd_float3(1.596, -0.813, 0.0)))
        
        // BT.601 full range
        let kColorConversion601FullRangeMatrix = matrix_float3x3(columns: (
            simd_float3(1.0,    1.0,    1.0),
            simd_float3(0.0,    -0.343, 1.765),
            simd_float3(1.4,    -0.711, 0.0)))
        
        // BT.709, which is the standard for HDTV.
        let kColorConversion709DefaultMatrix = matrix_float3x3(columns: (
            simd_float3(1.164,  1.164, 1.164),
            simd_float3(0.0, -0.213, 2.112),
            simd_float3(1.793, -0.533,   0.0)))
        
        //2.偏移量
        let kColorConversion601FullRangeOffset = vector_float3(-(16.0/255.0), -0.5, -0.5)
        
        //3.创建转化矩阵结构体.
        var matrix = ZConvertMatrix()
        //设置转化矩阵
        /*
         kColorConversion601DefaultMatrix；
         kColorConversion601FullRangeMatrix；
         kColorConversion709DefaultMatrix；
         */
        matrix.matrix = kColorConversion601FullRangeMatrix
        matrix.offset = kColorConversion601FullRangeOffset
        
        //4.创建转换矩阵缓存区.
        convertMatrix = mtkView.device?.makeBuffer(bytes: &matrix, length: MemoryLayout<ZConvertMatrix>.size, options: .storageModeShared)
    }
    
    // 设置纹理
    func setupTextureWithEncoder(encoder: MTLRenderCommandEncoder, sampleBuffer: CMSampleBuffer) {
        //1.从CMSampleBuffer读取CVPixelBuffer，
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {return}
        
        var textureY: MTLTexture!
        var textureUV: MTLTexture!
        
        //textureY 设置
        
        //2.获取纹理的宽高
        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)
        
        //3.像素格式:普通格式，包含一个8位规范化的无符号整数组件。
        let pixelFormat = MTLPixelFormat.r8Unorm
        
        //4.创建CoreVideo的Metal纹理
        var texture: CVMetalTexture!
        
        /*5. 根据视频像素缓存区 创建 Metal 纹理缓存区
         CVReturn CVMetalTextureCacheCreateTextureFromImage(CFAllocatorRef allocator,
         CVMetalTextureCacheRef textureCache,
         CVImageBufferRef sourceImage,
         CFDictionaryRef textureAttributes,
         MTLPixelFormat pixelFormat,
         size_t width,
         size_t height,
         size_t planeIndex,
         CVMetalTextureRef  *textureOut);
         
         功能: 从现有图像缓冲区创建核心视频Metal纹理缓冲区。
         参数1: allocator 内存分配器,默认kCFAllocatorDefault
         参数2: textureCache 纹理缓存区对象
         参数3: sourceImage 视频图像缓冲区
         参数4: textureAttributes 纹理参数字典.默认为NULL
         参数5: pixelFormat 图像缓存区数据的Metal 像素格式常量.注意如果MTLPixelFormatBGRA8Unorm和摄像头采集时设置的颜色格式不一致，则会出现图像异常的情况；
         参数6: width,纹理图像的宽度（像素）
         参数7: height,纹理图像的高度（像素）
         参数8: planeIndex.如果图像缓冲区是平面的，则为映射纹理数据的平面索引。对于非平面图像缓冲区忽略。
         参数9: textureOut,返回时，返回创建的Metal纹理缓冲区。
         */
        let status = CVMetalTextureCacheCreateTextureFromImage(nil, textureCache, pixelBuffer, nil, pixelFormat, width, height, 0, &texture)
        
        //6.判断textureCache 是否创建成功
        if status == kCVReturnSuccess {
            //7.转成Metal用的纹理
            textureY = CVMetalTextureGetTexture(texture)
        }
        //9.textureUV 设置(同理,参考于textureY 设置)
        let width2 = CVPixelBufferGetWidthOfPlane(pixelBuffer, 1)
        let height2 = CVPixelBufferGetHeightOfPlane(pixelBuffer, 1)
        
        let pixelFormat2 = MTLPixelFormat.rg8Unorm
        var texture2: CVMetalTexture!
        
        let status2 = CVMetalTextureCacheCreateTextureFromImage(nil, textureCache, pixelBuffer, nil, pixelFormat2, width2, height2, 1, &texture2)
        
        if status2 == kCVReturnSuccess {
            textureUV = CVMetalTextureGetTexture(texture2)
        }
        
        
        //10.判断textureY 和 textureUV 是否读取成功
        if textureY != nil && textureUV != nil {
            encoder.setFragmentTexture(textureY, index: Int(ZFragmentTextureIndexTextureY.rawValue))
            encoder.setFragmentTexture(textureUV, index: Int(ZFragmentTextureIndexTextureUV.rawValue))
        }
        
        //13.使用完毕,则将sampleBuffer 及时释放
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        viewportSize = vector_int2(Int32(size.width), Int32(size.height))
        
    }
    
    func draw(in view: MTKView) {
        //1.每次渲染都要单独创建一个CommandBuffer
        let commandBuffer = commandQueue.makeCommandBuffer()
        
        //2. 从CCAssetReader中读取图像数据
        //获取渲染描述信息
        //3.判断renderPassDescriptor 和 sampleBuffer 是否已经获取到了?
        if let renderPassDescriptor = view.currentRenderPassDescriptor, let samperBuffer = reader.readBuffer() {
            //4.设置renderPassDescriptor中颜色附着(默认背景色)
            //            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.5, 0.5, 1.0)
            
            //5.根据渲染描述信息创建渲染命令编码器
            let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
            
            //6.设置视口大小(显示区域)
            renderEncoder?.setViewport(MTLViewport(originX: 0.0, originY: 0.0, width: Double(viewportSize.x), height: Double(viewportSize.y), znear: 0.0, zfar: 1.0))
            
            //7.为渲染编码器设置渲染管道
            renderEncoder?.setRenderPipelineState(pipelineState)
            
            //8.设置顶点缓存区
            renderEncoder?.setVertexBuffer(vertices, offset: 0, index: Int(ZVertexInputIndexVertices.rawValue))
            
            //9.设置纹理(将sampleBuffer数据 设置到renderEncoder 中)
            setupTextureWithEncoder(encoder: renderEncoder!, sampleBuffer: samperBuffer)
            
            //10.设置片元函数转化矩阵
            renderEncoder?.setFragmentBuffer(convertMatrix, offset: 0, index: Int(ZFragmentBufferIndexMatrix.rawValue))
            
            //11.开始绘制
            renderEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: numVertices)
            
            //12.结束编码
            renderEncoder?.endEncoding()
            
            //13.显示
            commandBuffer?.present(mtkView.currentDrawable!)
        }
        //14.提交命令
        commandBuffer?.commit()
    }
}

