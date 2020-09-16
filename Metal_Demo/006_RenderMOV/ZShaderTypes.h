//
//  ZShaderTypes.h
//  Metal_Demo
//
//  Created by zsq on 2020/9/9.
//  Copyright © 2020 zsq. All rights reserved.
//

#ifndef ZShaderTypes_h
#define ZShaderTypes_h
#include <simd/simd.h>

//顶点数据结构
typedef struct {
    //顶点坐标(x,y,z,w)
    vector_float4 position;
    //纹理坐标(s,t)
    vector_float2 textureCoordinate;
}ZVertex;

//转换矩阵
typedef struct {
    //三维矩阵
    matrix_float3x3 matrix;
    //偏移量
    vector_float3 offset;
} ZConvertMatrix;

//顶点函数输入索引
typedef enum ZVertexInputIndex {
    ZVertexInputIndexVertices = 0,
} ZVertexInputIndex;

//片元函数缓存区索引
typedef enum ZFragmentBufferIndex {
    ZFragmentBufferIndexMatrix = 0,
} ZFragmentBufferIndex;

//片元函数纹理索引
typedef enum ZFragmentTextureIndex {
    ZFragmentTextureIndexTextureY = 0,
    ZFragmentTextureIndexTextureUV = 1,
} ZFragmentTextureIndex;

#endif /* ZShaderTypes_h */
