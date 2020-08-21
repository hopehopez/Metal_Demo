//
//  ShaderTypes.swift
//  002_Triangle
//
//  Created by zsq on 2020/8/21.
//  Copyright © 2020 zsq. All rights reserved.
//


import UIKit
import simd
// 缓存区索引值 共享与 shader 和 C 代码 为了确保Metal Shader缓存区索引能够匹配 Metal API Buffer 设置的集合调用
enum VertexInputIndex: Int{
    ///顶点
    case VertexInputIndexVertices = 0
    ///视图大小
    case VertexInputIndexViewportSize
};


///结构体: 顶点/颜色值
struct Vertex {
    // 像素空间的位置
    // 像素中心点(100,100)
    var position: vector_float4!
    // RGBA颜色
    var color: vector_float4!
}
class ShaderTypes: NSObject {

}


