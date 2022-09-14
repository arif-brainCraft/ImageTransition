//
//  TransformFilterWithMirror.metal
//  ImageTransition
//
//  Created by BCL Device7 on 24/8/22.
//

#include <metal_stdlib>
#include "BCLTransitionLib.h"

using namespace metalpetal;

struct VIn{
    float4 position[[attribute(0)]];
    float4 col0[[attribute(1)]];
    float4 col1[[attribute(2)]];
    float4 col2[[attribute(3)]];
    float4 col3[[attribute(4)]];
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


vertex VertexOut transformFilterWithMirrorVertex (const VIn  vertices [[ stage_in ]]){
    
    float4 aPosition = vertices.position;

    float4x4 orthographicMatrix = float4x4();
    orthographicMatrix.columns[0] = vertices.col0;
    orthographicMatrix.columns[1] = vertices.col1;
    orthographicMatrix.columns[2] = vertices.col2;
    orthographicMatrix.columns[3] = vertices.col3;

    VertexOut out;

    out.position = float4(aPosition.xyz, 1.0) * orthographicMatrix;
    out.textureCoordinate = aPosition.xy;

    return out;
}


