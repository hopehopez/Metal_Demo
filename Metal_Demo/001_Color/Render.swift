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
    
    func initWithMetalKitView(mtkView: MTKView) {
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
    }
    


    
}
