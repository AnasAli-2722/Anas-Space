// Holographic Glass Shader for Cyberpunk Glassmorphism
// Compatible with Flutter Impeller
#version 460 core

#include <flutter/runtime_effect.glsl>

// Uniforms provided by Flutter
uniform vec2 uSize;
uniform float uTime;

// Fragment shader output
out vec4 fragColor;

// Pseudo-random function for noise
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

// Smooth noise function
float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);
    
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

void main() {
    // Normalize coordinates
    vec2 uv = FlutterFragCoord().xy / uSize;
    
    // Scanline effect - scrolling transparency
    float scanline = sin((uv.y + uTime * 0.3) * 100.0) * 0.5 + 0.5;
    scanline = pow(scanline, 3.0) * 0.2;
    
    // Diagonal neon glow gradient
    float diagonal = (uv.x + uv.y) * 0.5;
    float pulse = sin(uTime * 2.0) * 0.5 + 0.5;
    
    // Cyan/Magenta mix
    vec3 neonCyan = vec3(0.0, 0.96, 1.0);
    vec3 neonMagenta = vec3(1.0, 0.0, 1.0);
    vec3 neonColor = mix(neonCyan, neonMagenta, diagonal);
    
    // Add animated noise for holographic effect
    float noiseVal = noise(uv * 10.0 + vec2(uTime * 0.1, 0.0));
    neonColor += vec3(noiseVal * 0.15);
    
    // Glow intensity
    float glow = pow(1.0 - abs(diagonal - 0.5) * 2.0, 2.0);
    glow = glow * (0.3 + pulse * 0.2);
    
    // Holographic shimmer
    float shimmer = noise(uv * 20.0 + vec2(uTime * 0.5, uTime * 0.3));
    shimmer = pow(shimmer, 2.0) * 0.4;
    
    // Combine effects
    vec3 finalColor = neonColor * (glow + shimmer);
    
    // Add scanline transparency
    float alpha = 0.4 + scanline + glow * 0.3;
    alpha = clamp(alpha, 0.2, 0.9);
    
    fragColor = vec4(finalColor, alpha);
}
