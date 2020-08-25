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
    var myrender: MyRender?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //1. 获取MTKView
        let view = self.view as! MTKView
        
        //2.为MTKView 设置MTLDevice(必须)
        //一个MTLDevice对象就代表这着一个GPU, 通常我们可以调用方法MTLCreateSystemDefaultDevice() 来获取代表默认的GPU单个对象.
        view.device = MTLCreateSystemDefaultDevice()

        //4. 创建Render
        //分开你的渲染循环:
        //在我们开发Metal 程序时, 将渲染循环分为自己创建的类, 是非常有用的一种方式, 使用单独的类, 我们可以更好管理初始化Metal, 以及Metal视图委托.
        render = Render.init(mtkView: view)

        render?.mtkView(view, drawableSizeWillChange: view.drawableSize)

        //6.设置MTKView 的代理(由CCRender来实现MTKView 的代理方法)
        view.delegate = render
        
//        myrender = MyRender.init(metalKitView: view)
//        myrender?.mtkView(view, drawableSizeWillChange: view.drawableSize)
//        view.delegate = myrender
    }


}

