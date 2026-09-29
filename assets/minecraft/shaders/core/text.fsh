#version 330
#extension GL_ARB_separate_shader_objects : require

#if !defined(IS_GUI) && !defined(IS_SEE_THROUGH)
#include <minecraft:fog.glsl>
#elif !defined(IS_SEE_THROUGH)
#include <retitled_titles:utils.glsl>
#include <minecraft:globals.glsl>
#endif

#include <minecraft:dynamictransforms.glsl>
#include <minecraft:oit.glsl>

uniform sampler2D Sampler0;

#if defined(IS_GUI) && !defined(IS_SEE_THROUGH)
const vec3[] GRADIENTS = vec3[](
    #include <retitled_titles:gradients.glsl>
);

// don't ask, I don't know either. I messed with values until something worked, as always.
float mod_gradient_offset(float _in) {
    return _in >= 0.5 ? _in - 0.001 : _in;
}
#endif

#if !defined(IS_GUI) && !defined(IS_SEE_THROUGH)
layout(location = 0) in float sphericalVertexDistance;
layout(location = 1) in float cylindricalVertexDistance;
#elif !defined(IS_SEE_THROUGH)
layout(location = 4) flat in int obj_type;
#endif

layout(location = 2) in vec4 vertexColor;
layout(location = 3) in vec2 texCoord0;

#ifndef OIT_ALPHA_ONLY
layout(location = 0) out vec4 fragColor;
#endif

vec4 calculateFinalColor(vec4 color) {
    #ifdef OIT_ACCUMULATE
    color = sampleColorForAccumulation(color);
    #endif

    #if !defined(IS_SEE_THROUGH) && !defined(IS_GUI)

    #ifdef OIT_ACCUMULATE
    vec4 fogColor = vec4(FogColor.rgb * color.a, FogColor.a);
    #else
    vec4 fogColor = FogColor;
    #endif

    color = apply_fog(color, sphericalVertexDistance, cylindricalVertexDistance, FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd, fogColor);
    #endif

    return color;
}


void main() {
    #ifdef IS_GRAYSCALE
    vec4 texColor = texture(Sampler0, texCoord0).rrrr;
    #else
    vec4 texColor = texture(Sampler0, texCoord0);
    #endif

    vec4 color = texColor * vertexColor * ColorModulator;

    if (color.a < 0.1) {
        discard;
    }


    #if defined(IS_GUI) && !defined(IS_SEE_THROUGH)
    vec4 texture_color = texture(Sampler0, texCoord0);
    if (texture_color.a < 0.001) {
        discard;
    }

    if ( obj_type == 16 ) {
        // that cool transition
        if ( !(texture_color.r >= 1.0-vertexColor.a) ) discard;

        int gradient_index = int( fract(vertexColor.b*2.0 + mod_gradient_offset(texture_color.g)) * 255.0);

        fragColor = vec4(
            mix(GRADIENTS[gradient_index], GRADIENTS[gradient_index+1], texture_color.b),
            1.0
        );

        int effect_ID = int(vertexColor.r * 255.0);
        switch (effect_ID) {
            // that blocky noise thing
            case 40:
            fragColor.rgb += vec3(rand_blocky_canvas(gl_FragCoord.xy, GameTime)) * texture_color.b;
        }

        return;
    }
    fragColor = color;
    #endif

    #ifdef OIT_ALPHA_ONLY
    executeAlphaOnlyPhase(gl_FragCoord.z, color.a);
    #else
    fragColor = calculateFinalColor(color);
    #endif
}