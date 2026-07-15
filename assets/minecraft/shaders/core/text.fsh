#version 330

#if !defined(IS_GUI) && !defined(IS_SEE_THROUGH)
#moj_import <minecraft:fog.glsl>
#elif !defined(IS_SEE_THROUGH)
#moj_import <retitled_titles:utils.glsl>
#moj_import <minecraft:globals.glsl>
#endif

#moj_import <minecraft:dynamictransforms.glsl>

uniform sampler2D Sampler0;

#if defined(IS_GUI) && !defined(IS_SEE_THROUGH)
const vec3[] GRADIENTS = vec3[](
    #moj_import <retitled_titles:gradients.glsl>
);

// don't ask, I don't know either. I messed with values until something worked, as always.
float mod_gradient_offset(float _in) {
    return _in >= 0.5 ? _in - 0.001 : _in;
}
#endif

#if !defined(IS_GUI) && !defined(IS_SEE_THROUGH)
in float sphericalVertexDistance;
in float cylindricalVertexDistance;
#elif !defined(IS_SEE_THROUGH)
flat in int obj_type;
#endif

in vec4 vertexColor;
in vec2 texCoord0;

out vec4 fragColor;

void main() {
#ifdef IS_GRAYSCALE
    vec4 texColor = texture(Sampler0, texCoord0).rrrr;
#else
    vec4 texColor = texture(Sampler0, texCoord0);
#endif

#ifdef IS_SEE_THROUGH
    vec4 color = texColor * vertexColor;
#else
    vec4 color = texColor * vertexColor * ColorModulator;
#endif
    if (color.a < 0.1) {
        discard;
    }

#ifdef IS_SEE_THROUGH
    fragColor = color * ColorModulator;
#elif defined(IS_GUI)
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
#else
    fragColor = apply_fog(color, sphericalVertexDistance, cylindricalVertexDistance, FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd, FogColor);
#endif
}