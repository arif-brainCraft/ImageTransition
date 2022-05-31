//
//  DoomScreenTransition.metal
//  ImageTransition
//
//  Created by BCL Device7 on 26/5/22.
//

#include <metal_stdlib>
#include "BCLTransitionLib.h"

using namespace metalpetal;

// Number of total bars/columns
constant int bars_dst = 10;

// Multiplier for speed ratio. 0 = no variation when going down, higher = some elements go much faster
constant float amplitude_dst = 3;

// Further variations in speed. 0 = no noise, 1 = super noisy (ignore frequency)
constant float noise_dst = 0.1;

// Speed variation horizontally. the bigger the value, the shorter the waves
constant float frequency_dst = 1;

// How much the bars seem to "run" from the middle of the screen first (sticking to the sides). 0 = no drip, 1 = curved drip
constant float dripScale_dst = 0.5;


// The code proper --------

constant float zoom_quickness = 0.8;

float nQuick(float zoom_quickness){
    return clamp(zoom_quickness,0.2,1.0) + 0.3;
}

float2 zoom(float2 uv, float amount) {
  return 0.5 + ((uv - 0.5) * (1.0-amount));
}

float rand_dst(int num) {
    return fract(mod(float(num) * 67123.313, 12.0) * sin(float(num) * 10.3) * cos(float(num)));
}

float wave_dst(int num) {
    float fn = float(num) * frequency_dst * 0.1 * float(bars_dst);
    return cos(fn * 0.5) * sin(fn * 0.5) * sin((fn+10.0) * 0.31) / 2.0 + 0.5;
}

float drip_dst(int num) {
    return sin(float(num) / float(bars_dst - 1) * 3.141592) * dripScale_dst;
}

float pos_dst(int num) {
    return (noise_dst == 0.0 ? wave_dst(num) : mix(wave_dst(num), rand_dst(num), noise_dst)) + (dripScale_dst == 0.0 ? 0.0 : drip_dst(num));
}

fragment float4 doomScreenTransitionFragment(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                    texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                    constant float & ratio [[ buffer(1) ]],
                                    constant float & progress [[ buffer(2) ]],
                                    sampler textureSampler [[ sampler(0) ]]) {
    
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    
    int bar = int(uv.x * (float(bars_dst)));
    float scale = 1.0 + pos_dst(bar) * amplitude_dst;
    float phase = progress * scale;
    float posY = uv.y / float2(1.0).y;
    float4 c;
    
    if (phase + posY < 1.0) {
        
        c = getFromColor(zoom(uv, smoothstep(0., nQuick(zoom_quickness), phase)),fromTexture,ratio,_fromR)  ;
    } else {
        
        c = getToColor(zoom(uv, smoothstep(0.0, nQuick(zoom_quickness),1.- phase)),toTexture,ratio,_toR);
    }
    
    return c;
}

 
