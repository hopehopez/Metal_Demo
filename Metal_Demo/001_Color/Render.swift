//
//  Render.swift
//  001_Color
//
//  Created by zsq on 2020/8/20.
//  Copyright © 2020 zsq. All rights reserved.
//

import UIKit
import MetalKit

struct Color {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double
}

class Render: NSObject, MTKViewDelegate {
    var device: MTLDevice?
    var commandQueue: MTLCommandQueue?
    
    static var growing = true
    static var primaryChannel = 0
    static var colorChannels = [1.0, 0.0, 0.0, 1.0]
   
    convenience init(mtkView: MTKView) {
        self.init()
        
        device = mtkView.device
        
        //Metal与GPU 交互的第一个对象
        commandQueue = device!.makeCommandQueue()
    }
    
    func makeFancyColo() -> Color {
        
        let DynamicColorRate = 0.015
        if Render.growing {
            let dynamicChannelIndex = (Render.primaryChannel+1)%3
            Render.colorChannels[dynamicChannelIndex] += DynamicColorRate
            if Render.colorChannels[dynamicChannelIndex] > 1.0 {
                Render.growing = false
                Render.primaryChannel = dynamicChannelIndex
            }
        } else {
            let dynamicChannelIndex = (Render.primaryChannel+2)%3
            Render.colorChannels[dynamicChannelIndex] -= DynamicColorRate
            if Render.colorChannels[dynamicChannelIndex] <= 1.0 {
                Render.growing = true
            }
        }
        
        let color = Color.init(red: Render.colorChannels[0], green: Render.colorChannels[1], blue: Render.colorChannels[2], alpha: Render.colorChannels[3])
        
        return color
        
    }
    
    //当MTKView视图发生大小改变时调用
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    //每当视图需要渲染时调用
    func draw(in view: MTKView) {
        
         //1. 获取颜色值
        let color = makeFancyColo()
        
        //2. 设置view的clearColor
        view.clearColor = MTLClearColorMake(color.red, color.green, color.blue, color.alpha)
        
        //3. Create a new command buffer for each render pass to the current drawable
        //使用MTLCommandQueue 创建对象并且加入到MTCommandBuffer对象中去.
        //为当前渲染的每个渲染传递创建一个新的命令缓冲区
        let commandBuffer = commandQueue?.makeCommandBuffer()
        commandBuffer?.label = "MyCommand"
        
        //4.从视图绘制中,获得渲染描述符
        //5.判断renderPassDescriptor 渲染描述符是否创建成功,否则则跳过任何渲染.
        if let renderPassDescriptor = view.currentRenderPassDescriptor {
            
            //6.通过渲染描述符renderPassDescriptor创建MTLRenderCommandEncoder 对象
            let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
            renderEncoder?.label = "renderEncoder"
            
            //7.我们可以使用MTLRenderCommandEncoder 来绘制对象,但是这个demo我们仅仅创建编码器就可以了,我们并没有让Metal去执行我们绘制的东西,这个时候表示我们的任务已经完成.
            //即可结束MTLRenderCommandEncoder 工作
            renderEncoder?.endEncoding()
            
            /*
             当编码器结束之后,命令缓存区就会接受到2个命令.
             1) present
             2) commit
             因为GPU是不会直接绘制到屏幕上,因此你不给出去指令.是不会有任何内容渲染到屏幕上.
             */
            //8.添加一个最后的命令来显示清除的可绘制的屏幕
            commandBuffer?.present(view.currentDrawable!)
        }
        
         //9.在这里完成渲染并将命令缓冲区提交给GPU
        commandBuffer?.commit()
    }
    


    
}
