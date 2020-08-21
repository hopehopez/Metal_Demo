//
//  Shaders.metal
//  002_Triangle
//
//  Created by zsq on 2020/8/21.
//  Copyright © 2020 zsq. All rights reserved.
//

#include <metal_stdlib>


//使用命名空间 Metal
using namespace metal;
// 导入Metal shader 代码和执行Metal API命令的C代码之间共享的头
#import "ShaderTypes.h"

// 顶点着色器输出和片段着色器输入
//结构体
struct RasterizerData {
    //处理空间的顶点信息
    float4 clipSpacePosition [[position]];
    //颜色
    float4 color;
};

//顶点着色函数
vertex RasterizerData vertexShader(uint vertexID [[vertex_id]],
             constant Vertex *vertices [[buffer(VertexInputIndexVertices)]],
             constant vector_uint2 *viewportSizePointer [[buffer(VertexInputIndexViewportSize)]])
{
    RasterizerData out;
    out.clipSpacePosition = vertices[vertexID].position;

    //把我们输入的颜色直接赋值给输出颜色. 这个值将于构成三角形的顶点的其他颜色值插值,从而为我们片段着色器中的每个片段生成颜色值.
    out.color = vertices[vertexID].color;

    //完成! 将结构体传递到管道中下一个阶段:
    return out;
}


fragment float4 fragmentShader(RasterizerData in [[stage_in]])
{
    
    //返回输入的片元颜色
    return in.color;
}
