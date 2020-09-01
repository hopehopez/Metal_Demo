//
//  ViewController.swift
//  004_TgaTexture
//
//  Created by zsq on 2020/9/1.
//  Copyright © 2020 zsq. All rights reserved.
//

import UIKit
import MetalKit
class ViewController: UIViewController {
    var render: Render?
    override func viewDidLoad() {
        super.viewDidLoad()
        let mtkView = view as! MTKView
        mtkView.device = MTLCreateSystemDefaultDevice()
        render = Render(mtkView: mtkView)
        render?.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)
        mtkView.delegate = render
    }


}

