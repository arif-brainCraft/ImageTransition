//
//  FlareOverlay.metal
//  ImageTransition
//
//  Created by BCL Device7 on 24/8/22.
//

#include <metal_stdlib>
#include "BCLTransitionLib.h"

using namespace metalpetal;

float dis(float2 a,float2 b){
    return sqrt((a.x-b.x)*(a.x-b.x) + (a.y-b.y)*(a.y-b.y));
}

float4 oneShade(float2 uv,float progress,float4 oneColor, float2 oneCenter, float oneRadius){
    float d = dis(float2(oneCenter.x,oneCenter.y + 0.3*sin(PI*progress)),uv);
    return (d < oneRadius) ? oneColor*progress*(1.0 - d/oneRadius) : float4(0.0);
}

float4 twoShade(float2 uv,float progress,float4 twoColor, float2 twoCenter, float twoRadius){
    float d = dis(twoCenter,uv);
    return (d < twoRadius) ? twoColor*progress*(1.0 - d/twoRadius) : float4(0.0);
}

float4 threeShade(float2 uv,float progress,float4 threeColor, float2 threeCenter, float threeRadius){
    float d = dis(threeCenter + 0.3*sin(PI*progress),uv);
    return (d < threeRadius) ? threeColor*progress*(1.0 - d/threeRadius) : float4(0.0);
}

fragment float4 flareOverlay (VertexOut vertexIn [[ stage_in ]],
                              texture2d<float, access::sample> sTexture [[ texture(0) ]],
                              
                              constant float4 &oneColor[[buffer(0)]],
                              constant float2 &oneCenter[[buffer(1)]],
                              constant float &oneRadius[[buffer(2)]],
                              
                              constant float4 &twoColor[[buffer(3)]],
                              constant float2 &twoCenter[[buffer(4)]],
                              constant float &twoRadius[[buffer(5)]],
                              
                              constant float4 &threeColor[[buffer(6)]],
                              constant float2 &threeCenter[[buffer(7)]],
                              constant float &threeRadius[[buffer(8)]],
                              
                              constant float & ratio [[ buffer(9) ]],
                              constant float & progress [[ buffer(10) ]]){
    
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(sTexture.get_width())/float(sTexture.get_height());
    
    
    return oneShade(uv,progress,oneColor,oneCenter,oneRadius) + twoShade(uv,progress,twoColor,twoCenter,twoRadius) + getFromColor(uv,sTexture,ratio,_fromR) + threeShade(uv,progress,threeColor,threeCenter,threeRadius);
}


