//
//  ShakyZoom.metal
//  ImageTransition
//
//  Created by BCL Device7 on 31/8/22.
//

#include <metal_stdlib>
#include "BCLTransitionLib.h"

using namespace metalpetal;

float2 sZ_rotZ( float2 p, float a) {
    float c = cos(a);
    float s = sin(a);
    
    return matrix_float2x2(c, -s, s, c) * p;
}

float2 sZ_zoom( float2 uv, float amount) {
    return 0.5 + ((uv - 0.5) * (amount)) ;
}

fragment float4 shakyZoom (VertexOut vertexIn [[ stage_in ]],
                            texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                            texture2d<float, access::sample> toTexture [[ texture(1) ]],
                             constant float & zoom_quickness [[ buffer(0) ]],
                           constant float & rotation [[ buffer(1) ]],
                            constant float & ratio [[ buffer(2) ]],
                            constant float & progress [[ buffer(3) ]]) {
    
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    float nQuick = clamp(zoom_quickness,0.2,1.0);
    float2 p =  float2(0.0);
    
    float rot = rotation;
    
    rot = rot + sin(20.0 * progress);
    
    if (progress < 0.1){
        rot += sin(progress * 100.0);
    }
    p = uv - 0.5;
    p = sZ_rotZ(p,rot * 3.1416/180.0);
    p = p + 0.5;
    
    p = sZ_zoom(p,smoothstep(0.0, nQuick, progress + 0.3));
    
        
    return getFromColor(p,fromTexture,ratio,_fromR);

//    return mix(
//               getFromColor(p,fromTexture,ratio,_fromR),
//               getToColor(vertexIn.textureCoordinate,toTexture,ratio,_toR),
//               smoothstep(nQuick-0.2, 1.0, progress)
//               );
}
