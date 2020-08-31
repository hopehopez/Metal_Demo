//
//  Shaders.metal
//  003_BaseBuffer
//
//  Created by zsq on 2020/8/28.
//  Copyright © 2020 zsq. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


// 导入Metal shader 代码和执行Metal API命令的C代码之间共享的头
#import "ShaderTypes.h"

// 顶点着色器输出和片段着色器输入
//结构体
typedef struct
{
    //处理空间的顶点信息
    float4 clipSpacePosition [[position]];
    
    //颜色
    float4 color;
    
} RasterizerData;

//顶点着色函数
vertex RasterizerData vertexShader(uint vertexID [[vertex_id]],
                                   constant ZVertex *vertices [[buffer(ZVertexInputIndexVertices)]],
                                   constant vector_uint2 *viewportSizePointer [[buffer(ZVertexInputIndexViewportSize)]]) {
    /*
     处理顶点数据:
     1) 执行坐标系转换,将生成的顶点剪辑空间写入到返回值中.
     2) 将顶点颜色值传递给返回值
     */
    
    //定义out
    RasterizerData out;
    
    //初始化输出剪辑空间位置
    out.clipSpacePosition = vector_float4(0.0, 0.0, 0.0, 1.0);
    
    // 索引到我们的数组位置以获得当前顶点
    // 我们的位置是在像素维度中指定的.
    
}
