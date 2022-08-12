//
//  Day2_shaders.metal
//  ARDistortion
//
//  Created by ミズキ on 2022/08/12.
//

#include <metal_stdlib>
using namespace metal;
#include "SceneKit/scn_metal"

struct VertexInput {
    float3 position [[attribute(SCNVertexSemanticPosition)]];
    float3 normal [[attribute(SCNVertexSemanticNormal)]];
    float3 texCoords [[attribute(SCNVertexSemanticTexcoord0)]];
};

struct NodeBuffer {
    float4x4 modelViewProjectionTransform;
    float4x4 modelViewTransform;
};

float2 getBackgroundCoordinate(
                      constant float4x4& displayTransform,
                      constant float4x4& modelViewTransform,
                      constant float4x4& projectionTransform,
                               float4 position) {
                                   float4 vertextCamera = modelViewTransform * position;
                                   float4 vertexClipSpace = projectionTransform * vertextCamera;
                                   vertexClipSpace /= vertexClipSpace.w;
                                   
                                   float4 vertexImageSpace = float4(vertexClipSpace.xy * 0.5 + 0.5, 0.0, 1.0);
                                   vertexImageSpace.y = 1.0 - vertexImageSpace.y;
                                   return (displayTransform * vertexImageSpace).xy;
                               }

struct GeometryEffectInOut {
    float4 position [[ position ]];
    float2 backgroundTextureCoords;
};

vertex GeometryEffectInOut geometryEffectVertextShader(VertexInput in [[stage_in ]],
                                                            constant SCNSceneBuffer& scn_frame [[ buffer(0) ]],
                                                            constant NodeBuffer& scn_node [[ buffer(1) ]],
                                                            constant float4x4& u_displayTransform [[ buffer(2) ]],
                                                            constant float& u_time [[ buffer(3) ]]) {
    GeometryEffectInOut out;
    // 入ってきた逆行列 modelViewTransrom
    out.backgroundTextureCoords = getBackgroundCoordinate(u_displayTransform, scn_node.modelViewTransform,
                                                          scn_frame.projectionTransform,
                                                          float4(in.position,
                                                                 1.0));
    
    
    // 波の高さ
    float waveHeight = 0.5;
    // 波の頻度
    float waveFrequency = 20.0;
    
    // positionと原点の距離
    float len = length(in.position.xy);
    
    float blending = max(0.0, 0.5 - len);
    in.position.z += sin(len * waveFrequency + u_time * 5) * waveHeight * blending;
    out.position = scn_node.modelViewProjectionTransform * float4(in.position, 1.0);
    return out;
}

fragment float4 geometryEffectFragmentShader(GeometryEffectInOut in [[ stage_in ]], texture2d<float, access::sample> diffuseTexture [[ texture(0) ]]) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    float3 color = diffuseTexture.sample(textureSampler, in.backgroundTextureCoords).rgb;
    return float4(color, 1.0);
}



