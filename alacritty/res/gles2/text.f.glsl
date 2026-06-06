varying mediump vec2 TexCoords;
varying mediump vec3 fg;
varying highp float colored;
varying mediump vec4 bg;

uniform highp int renderingPass;
uniform sampler2D mask;

#define COLORED 1

mediump float max_rgb(mediump vec3 mask) {
    return max(max(mask.r, mask.g), mask.b);
}

void render_text() {
    // fressh fork: this local is named `texel` (upstream named it `mask`). Naming it
    // `mask` shadows the `mask` sampler inside its own initializer; the Mali GLSL ES
    // compiler binds the local there, so `texture2D(mask, ...)` resolves to
    // `texture2D(vec4, vec2)` -> no matching overload -> the shader fails to compile ->
    // the renderer never initializes -> blank terminal on device. (The desktop/emulator
    // compiler is lenient and binds the sampler, so it only broke on real hardware.)
    mediump vec4 texel = texture2D(mask, TexCoords);
    mediump float m_rgb = max_rgb(texel.rgb);

    if (renderingPass == 1) {
        gl_FragColor = vec4(texel.rgb, m_rgb);
    } else if (renderingPass == 2) {
        gl_FragColor = bg * (vec4(m_rgb) - vec4(texel.rgb, m_rgb));
    } else {
        gl_FragColor = vec4(fg, 1.) * vec4(texel.rgb, m_rgb);
    }
}

// Render colored bitmaps.
void render_bitmap() {
    if (renderingPass == 2) {
        discard;
    }
    // fressh fork: renamed `mask` -> `texel`, same self-shadow compile fix as render_text.
    mediump vec4 texel = texture2D(mask, TexCoords);
    if (renderingPass == 1) {
        gl_FragColor = texel.aaaa;
    } else {
        gl_FragColor = texel;
    }
}

void main() {
    // Handle background pass drawing before anything else.
    if (renderingPass == 0) {
        if (bg.a == 0.0) {
            discard;
        }

        gl_FragColor = vec4(bg.rgb * bg.a, bg.a);
        return;
    }

    if (int(colored) == COLORED) {
        render_bitmap();
    } else {
        render_text();
    }
}
