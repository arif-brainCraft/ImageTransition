//
//  DirectionalSlide.metal
//  ImageTransition
//
//  Created by BCL Device7 on 21/6/22.
//

#include <metal_stdlib>
#include "BCLTransitionLib.h"

using namespace metalpetal;

//constant float2 direction = float2(0.0,1.0);

fragment float4 directionalSlideFragment (VertexOut vertexIn [[ stage_in ]],
                   texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                   texture2d<float, access::sample> toTexture [[ texture(1) ]],
                    constant float2 & direction [[ buffer(0) ]],

                   constant float & ratio [[ buffer(1) ]],
                   constant float & progress [[ buffer(2) ]],
                   sampler textureSampler [[ sampler(0) ]]) {
    
    float2 p = vertexIn.textureCoordinate;
    p.y = 1.0 - p.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    
    float2 uv = p + progress * sign(direction);
    float2 f = fract(uv);
    return mix(
               getToColor(f, toTexture, ratio, _toR),
               getFromColor(f,fromTexture,ratio,_fromR),
               step(0.0, uv.y) * step(uv.y, 1.0) * step(0.0, uv.x) * step(uv.x, 1.0)
               );
}
