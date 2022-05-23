//
//  DreamyWindowSlice.metal
//  ImageTransition
//
//  Created by BCL Device7 on 23/5/22.
//

#include <metal_stdlib>
#include "BCLTransitionLib.h"

using namespace metal;


constant float count          = 5.0;
constant float smoothness     = 2;
constant float speed          = 1.5;
constant float zoom_quickness = 0.1;

constant float nQuick = clamp(zoom_quickness,0.1,0.3);

float2 zoom(float2 uv, float amount,float2 center) {
    return center.x + ((uv - center) * (1.0-amount));
}
float2 offset(float progress, float x, float theta) {
    float phase = progress*progress + progress + theta;
    float shifty = 0.03*progress*cos(10.0*(progress+x));
    return float2(0, shifty);
}

fragment float4 dreamyWindowSliceFragment (metalpetal::VertexOut vertexIn [[ stage_in ]],
                                  texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                  texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                  constant float & ratio [[ buffer(3) ]],
                                  constant float & progress [[ buffer(4) ]]) {
    
    float2 p = vertexIn.textureCoordinate;
    p.y = 1.0 - p.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    
    float pr = smoothstep(-smoothness, 0.0, p.y - progress * (1.0 + smoothness));
    float s = step(pr, fract(count * p.x) * speed);
    float qr = smoothstep(-smoothness, 0.0, p.x - progress * (1.0 + smoothness));
    float t = step(qr,fract(count * p.y) * speed);
    float st = s * t;
    float cp = (  smoothstep(cos( st), 0.0, pr + qr ));
    float2 tempA = p;//zoom(p, smoothstep(0.0, nQuick, cp),float2(pr * qr));
    float4  a = metalpetal:: getFromColor(tempA + offset(cp, tempA.x - cp, 0.0),fromTexture,ratio,_fromR);
    float4 b = metalpetal:: getToColor( p + offset(1.0-cp, p.x - cp , 3.14),toTexture,ratio,_toR);
    
    return mix(a, b, sqrt(cp));
}
