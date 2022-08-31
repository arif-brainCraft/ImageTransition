//
//  TransformFilterWithMirror.metal
//  ImageTransition
//
//  Created by BCL Device7 on 24/8/22.
//

#include <metal_stdlib>
#include "BCLTransitionLib.h"

using namespace metalpetal;

struct vertexIn{
    float4 position[[attribute(0)]];
    float4 color[[attribute(1)]];
};

fragment float4 transformFilterWithMirrorFragment (VertexOut vertexIn [[ stage_in ]],
                              texture2d<float, access::sample> sTexture [[ texture(0) ]],
                              constant matrix_float4x4 & transformMatrix [[ buffer(0) ]],
                              constant float & low [[ buffer(1) ]],
                              constant float & high [[ buffer(2) ]],

                              constant float & ratio [[ buffer(3) ]],
                              constant float & progress [[ buffer(4) ]]
){
    float2 p = vertexIn.textureCoordinate;
    p.y = 1.0 - p.y;
    float _fromR = float(sTexture.get_width())/float(sTexture.get_height());
    
    
    float4 uv = float4(p.xy, 1.0, 0.0);
    uv -= float4(0.5, 0.5, 0.0, 0.0);
    uv = transformMatrix * uv;
    uv += float4(0.5, 0.5, 0.0, 0.0);
    float4 color = getFromColor(uv.xy, sTexture, ratio, _fromR);

    return (uv.y > high || uv.y < low) ? float4(0.0) : color;
}

vertex float4 transformFilterWithMirrorVertex (const vertexIn vertexin [[stage_in]],
                                constant matrix_float4x4 & rot [[ buffer(0) ]],
                                constant float4 &aPosition [[buffer(1)]],
                             constant float4x4 & orthographicMatrix [[buffer(2)]]){

    float4 color = float4(aPosition.xyz, 1.0) * orthographicMatrix;
    return color;
}
/*

precision highp float;
varying highp float2 vTextureCoord;
uniform lowp sampler2D sTexture;
uniform mat4 transformMatrix;
uniform float low;
uniform float high;
    
    */

