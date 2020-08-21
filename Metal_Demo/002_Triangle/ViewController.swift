//
//  ViewController.swift
//  001_Color
//
//  Created by zsq on 2020/8/20.
//  Copyright © 2020 zsq. All rights reserved.
//

import UIKit
import MetalKit
class ViewController: UIViewController {
    var render:Render?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //1. 获取MTKView
        let view = self.view as! MTKView
        
        //2.为MTKView 设置MTLDevice(必须)
        //一个MTLDevice对象就代表这着一个GPU, 通常我们可以调用方法MTLCreateSystemDefaultDevice() 来获取代表默认的GPU单个对象.
        view.device = MTLCreateSystemDefaultDevice()
        
        //3.判断是否设置成功
        if view.device == nil {
            print("Metal is not supported on this device")
            return
        }
        
        //4. 创建Render
        //分开你的渲染循环:
        //在我们开发Metal 程序时, 将渲染循环分为自己创建的类, 是非常有用的一种方式, 使用单独的类, 我们可以更好管理初始化Metal, 以及Metal视图委托.
        render = Render.init(mtkView: view)
        
        //5.判断render 是否创建成功
        if render == nil {
            print("Renderer failed initialization")
            return
        }
        
        //6.设置MTKView 的代理(由CCRender来实现MTKView 的代理方法)
        view.delegate = render
        
        //7.视图可以根据视图属性上设置帧速率(指定时间来调用drawInMTKView方法--视图需要渲染时调用)
        view.preferredFramesPerSecond = 60
        
    }


}

