//
//  ShaderTypes.h
//  Metal_Demo
//
//  Created by zsq on 2020/8/28.
//  Copyright © 2020 zsq. All rights reserved.
//

#ifndef ShaderTypes_h
#define ShaderTypes_h
/*
 介绍:
 头文件包含了 Metal shaders 与C/OBJC 源之间共享的类型和枚举常数
*/
#include <simd/simd.h>

//结构体: 顶点/颜色值
typedef struct
{
    // 像素空间的位置
    // 像素中心点(100,100)
    vector_float2 position;

    // RGBA颜色
    vector_float4 color;
} ZVertex;


// 缓存区索引值 共享与 shader 和 C 代码 为了确保Metal Shader缓存区索引能够匹配 Metal API Buffer 设置的集合调用
typedef enum ZVertexInputIndex
{
    //顶点
    ZVertexInputIndexVertices     = 0,
    //视图大小
    ZVertexInputIndexViewportSize = 1,
} ZVertexInputIndex;

#endif /* ShaderTypes_h */
