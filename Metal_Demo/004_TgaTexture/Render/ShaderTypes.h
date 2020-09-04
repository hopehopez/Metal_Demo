//
//  ShaderTypes.h
//  Metal_Demo
//
//  Created by zsq on 2020/9/1.
//  Copyright © 2020 zsq. All rights reserved.
//
/*
介绍:
头文件包含了 Metal shaders 与C/OBJC 源之间共享的类型和枚举常数
*/
#ifndef ShaderTypes_h
#define ShaderTypes_h
#include <simd/simd.h>

// 缓存区索引值 共享与 shader 和 C 代码 为了确保Metal Shader缓存区索引能够匹配 Metal API Buffer 设置的集合调用
typedef enum ZVertexInputIndex{
    ZVertexInputVertices = 0,
    ZVertexInputViewportSize = 1,
} ZVertexInputIndex;

//纹理索引
typedef enum ZTextureIndex{
    ZTextureIndexBaseColor = 0,
}ZTextureIndex;

//结构体: 顶点/纹理坐标
typedef struct {
    // 像素空间的位置
    // 像素中心点(100,100)
    vector_float2 position;
    // 2D 纹理
    vector_float2 textureCoordinate;
} ZVertex;


#endif /* ShaderTypes_h */
 
