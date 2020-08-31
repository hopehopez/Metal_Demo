//
//  ViewController.swift
//  003_BaseBuffer
//
//  Created by zsq on 2020/8/28.
//  Copyright © 2020 zsq. All rights reserved.
//

import UIKit
import MetalKit
class ViewController: UIViewController {
    var render: Render?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let mtkView = view as! MTKView
        mtkView.device = MTLCreateSystemDefaultDevice()
        render = Render(mtkView: mtkView)
        render?.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)
        mtkView.delegate = render
        
    }


}

