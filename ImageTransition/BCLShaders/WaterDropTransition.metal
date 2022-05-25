//
//  BCLWaterDropTransition.metal
//  ImageTransition
//
//  Created by BCL Device7 on 23/5/22.
//

#include <metal_stdlib>
#include "BCLTransitionLib.h"

using namespace metalpetal;

constant float downAmplitude = 20;
constant float upAmplitude   = 30;

constant float upSpeed       = 0.7;
constant float downSpeed     = 0.1;

fragment float4 waterDropFragment(metalpetal::VertexOut vertexIn [[ stage_in ]],
                                  texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                  texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                  constant float & ratio [[ buffer(3) ]],
                                  constant float & progress [[ buffer(4) ]]) {
    
    float2 p = vertexIn.textureCoordinate;
    p.y = 1.0 - p.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    float2 downDir = p ;//- vec2(.5);
    float2 upDir = float2(1.0) - p;
    float downDist = length(downDir) - progress;
    float upDist = length(upDir) - progress ;
    
    float progressDirection = progress;
    
    
    if (upDist < progress){
        
        //return mix(getFromColor( p), getToColor( p), 0.0);
        float2 offset = upDir * sin(upDist * upAmplitude - progress * upSpeed);
        float4 color = mix(metalpetal::getFromColor( p + offset,fromTexture,ratio,_fromR), metalpetal::getToColor( p,toTexture,ratio,_toR), progress);
        return mix(color, metalpetal::getToColor( p,toTexture,ratio,_toR), progress);
    }else if (downDist < (progress)){
        float2 offset = downDir * sin(downDist * downAmplitude - progress * downSpeed);
        float4 color = mix(metalpetal::getFromColor( p + offset,fromTexture,ratio,_fromR), metalpetal::getToColor( p,toTexture,ratio,_toR), progress);
        return mix(metalpetal::getFromColor( p + offset,fromTexture,ratio,_fromR), metalpetal::getToColor( p,toTexture,ratio,_toR), progress);
    }else{
        //return mix(getFromColor( p), getToColor( p), progress);
        return metalpetal::getFromColor( p,fromTexture,ratio,_fromR);
    }
    
}
