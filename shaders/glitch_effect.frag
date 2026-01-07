// Glitch Effect Shader for Text/UI Elements
// Compatible with Flutter Impeller
#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;
uniform float uIntensity; // 0.0 to 1.0

out vec4 fragColor;

float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;
    
    // Glitch blocks
    float blockY = floor(uv.y * 20.0);
    float glitchBlock = step(0.95, random(vec2(blockY, floor(uTime * 5.0))));
    
    // RGB chromatic aberration
    float offset = glitchBlock * uIntensity * 0.02;
    vec2 uvR = uv + vec2(offset, 0.0);
    vec2 uvG = uv;
    vec2 uvB = uv - vec2(offset, 0.0);
    
    // Scanline interference
    float scanline = sin(uv.y * 800.0 + uTime * 10.0) * 0.5 + 0.5;
    scanline = pow(scanline, 5.0) * uIntensity;
    
    // Color shift
    vec3 baseColor = vec3(0.0, 0.96, 1.0); // Neon cyan
    vec3 glitchColor = mix(baseColor, vec3(1.0, 0.0, 1.0), glitchBlock);
    
    // Add scanline distortion
    glitchColor += vec3(scanline * 0.3);
    
    float alpha = 1.0;
    
    fragColor = vec4(glitchColor, alpha);
}
