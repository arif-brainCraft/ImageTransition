//
//  WhiteMinimalBgFilter.metal
//  ImageTransition
//
//  Created by BCL Device7 on 14/6/22.
//

#include <metal_stdlib>
#include "BCLTransitionLib.h"

using namespace metalpetal;

constant float gt = .0075;
constant half mt = .7;
constant half maxWidth = 0.35;

bool isGrey(float2 uv,float p) {
    p = sin(.5 * 3.14159 * p);
    float b = .5 - maxWidth*p;
    if(uv.x < b) return false;
    if(uv.y < b) return false;
    if(1.-uv.x < b) return false;
    if(1.-uv.y < b) return false;
    float d = abs(uv.x - b);
    d = min(d,abs(uv.y - b));
    d = min(d,abs(uv.x - 1. + b));
    d = min(d,abs(uv.y - 1. + b));
    if(d < gt*p) return true;
    return false;
}

fragment float4 whiteMinimalBgFilterFragment (VertexOut vertexIn [[ stage_in ]],
                   texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                   texture2d<float, access::sample> toTexture [[ texture(1) ]],
                   constant float & ratio [[ buffer(1) ]],
                   constant float & progress [[ buffer(2) ]],
                   sampler textureSampler [[ sampler(0) ]]) {
    
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    if(isGrey(uv,progress)) return float4(.5,.5,.5,1.);
    return mix(getFromColor(uv,fromTexture,ratio,_fromR),float4(1.),mt);
    
}

