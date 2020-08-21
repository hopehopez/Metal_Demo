//
//  ShaderTypes.h
//  Metal_Demo
//
//  Created by zsq on 2020/8/21.
//  Copyright © 2020 zsq. All rights reserved.
//

#ifndef ShaderTypes_h
#define ShaderTypes_h

// 缓存区索引值 共享与 shader 和 C 代码 为了确保Metal Shader缓存区索引能够匹配 Metal API Buffer 设置的集合调用
typedef enum VertexInputIndex
{
    //顶点
    VertexInputIndexVertices     = 0,
    //视图大小
    VertexInputIndexViewportSize = 1,
} VertexInputIndex;


//结构体: 顶点/颜色值
typedef struct
{
    // 像素空间的位置
    // 像素中心点(100,100)
    vector_float4 position;

    // RGBA颜色
    vector_float4 color;
} Vertex;
#endif /* ShaderTypes_h */
