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
        @__attribute__
        //定义一个TGA文件的头.
        struct __attribute__ (packed)) TGAHeader {
            var IDSize: UInt8!          // ID信息
            var colorMapType: UInt8!    // 颜色类型
            var imageType: UInt8!       // 图片类型 0=none, 1=indexed, 2=rgb, 3=grey, +8=rle packed
           
            
            var colorMapStart: Int16!   // 调色板中颜色映射的偏移量
            var colorMapLength: Int16!  // 在调色板的颜色数
            var colorMapBpp: UInt8!     // 每个调色板条目的位数
            
            var xOffset: UInt16!        // 图像开始右方的像素数
            var yOffset: UInt16!        // 图像开始下方的像素数
            var width: UInt16!          // 像素宽度
            var height: UInt16!         // 像素高度
            var bitsPerPixel: UInt8!    // 每像素的位数 8,16,24,32
            var descriptor: UInt8!      // bits描述 (flipping, etc)
        }
        
        guard let fileData = try? Data(contentsOf: tgaLocation, options: Data.ReadingOptions.mappedIfSafe) else {
            print("打开TGA文件失败")
            return
        }
        
        //data转bytes
        let bytes = [UInt8](fileData)
        
        //定义TGAHeader对象
        var tga: TGAHeader!
        
    }
}
