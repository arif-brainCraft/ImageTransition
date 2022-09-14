//
//  TextureOverlayWithTranslationFilter.metal
//  ImageTransition
//
//  Created by BCL Device7 on 24/8/22.
//

#include <metal_stdlib>
#include "BCLTransitionLib.h"

using namespace metalpetal;


float2 getOverlayPoint( float2 uv,float progress){
    uv.y += progress;
    if(uv.y > 1.0) uv.y = uv.y - 1.0;
    return uv;
}


float4 getBlendedColor(  float4 s,  float4 o){
    float4 dst =   float4(1.0);
    dst.rgb = (s.rgb + o.rgb * o.a);
    return dst;
}

fragment float4 textureOvelayWithTransition(VertexOut vertexIn [[ stage_in ]],
                  texture2d<float, access::sample> sTexture [[ texture(0) ]],
                  texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                  constant float & opacityMul [[ buffer(0) ]],
                  constant float & frameRatio [[ buffer(1) ]],
                  constant float & ratio [[ buffer(2) ]],
                  constant float & progress [[ buffer(3) ]]){

    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(sTexture.get_width())/float(sTexture.get_height());
    float _toR = float(overlayTexture.get_width())/float(overlayTexture.get_height());

    
    float4 sColor = getFromColor(uv, sTexture, ratio, _fromR);
    uv.y /= frameRatio;
    float4 oColor = getToColor(getOverlayPoint(uv, progress), overlayTexture, ratio,_toR );
    return mix(sColor,getBlendedColor(sColor,oColor),opacityMul);
}

