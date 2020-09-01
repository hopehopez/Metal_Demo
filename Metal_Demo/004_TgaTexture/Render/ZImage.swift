//
//  ZImage.swift
//  004_TgaTexture
//
//  Created by zsq on 2020/9/1.
//  Copyright © 2020 zsq. All rights reserved.
//

import UIKit

class ZImage: NSObject {

    convenience init(tgaLocation: URL) {
        self.init()
        
        let fileExtension = tgaLocation.pathExtension
        guard fileExtension.lowercased() == "tga" else {
            print("只能加载tga文件")
            return
        }
        
        //定义一个TGA文件的头.
        typede
        
    }
}
