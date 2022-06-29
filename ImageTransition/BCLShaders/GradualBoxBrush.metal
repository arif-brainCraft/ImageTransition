//
//  GradualBoxBrush.metal
//  ImageTransition
//
//  Created by BCL Device7 on 28/6/22.
//

#include <metal_stdlib>
#include "BCLTransitionLib.h"

using namespace metalpetal;


constant float mt = .9;
constant float radius = 0.4;
constant float width = 0.02;
constant int start = 0;

bool isOnBox(float2 uv,float p){
    
    float angle = clamp(float(start),0.0,3.0);
    
    float a = 0.0 - angle, b = 1.0 - angle, c = 2.0 - angle,d = 3.0 - angle;
    
    a = a < 0.0 ? 4.0 + a : a;
    b = b < 0.0 ? 4.0 + b : b;
    c = c < 0.0 ? 4.0 + c : c;
    d = d < 0.0 ? 4.0 + d : d;
    
    float r = (0.5 - radius);
    float progress = (p ) * 4.0;
    
    if (uv.x >= (r) && uv.x <= ((1.0 - r) * smoothstep(a,a + 1.0,progress))
        && uv.y >= r && uv.y <= (r + width)){
        return true;
    } else if (uv.y >= (r) && uv.y <= ((1.0 - r ) * smoothstep(b,b + 1.0,progress))
               && uv.x >= (1.0 - r - width) && uv.x <= (1.0 - r )){
        return true;
    }else if (uv.x >= (1.0 + r - smoothstep(c,c + 1.0,progress)) && uv.x <= (1.0 - r) && uv.y >= (1.0 - r - width) && uv.y <= (1.0 - r)){
        return true;
    }else if (uv.y <= (1.0 - r) && uv.y >= (1.0 + r  - smoothstep(d,d + 1.0,progress))
              && uv.x >= (r) && uv.x <= (r + width)){
        return true;
    }
    
    return false;
}

fragment float4 gradualBoxBrushFragment (VertexOut vertexIn [[ stage_in ]],
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
    
    if(isOnBox(p,smoothstep(0.3,0.7,progress))) return float4(.5,.5,.5,1.);
    return mix(getFromColor(p, fromTexture, ratio, _fromR),float4(1.),mt);
    
}

