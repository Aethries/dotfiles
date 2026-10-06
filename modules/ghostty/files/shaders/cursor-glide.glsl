// Ghostty 1.3+: cursor-opacity = 0, cursor-text = cell-foreground,
// alpha-blending = linear-corrected, custom-shader-animation = true.
// Draw the caret itself, with adaptive duration for rapid typing & IME smoothness.

const float JUMP_MOVE_SECONDS = 0.080;
const float TYPE_MOVE_SECONDS = 0.040;
const float IDLE_DELAY = 0.45;
const float PULSE_SECONDS = 1.6;
const float MIN_IDLE_OPACITY = 0.25;

vec3 toLinear(vec3 color) {
    return mix(color / 12.92, pow((color + 0.055) / 1.055, vec3(2.4)),
        step(vec3(0.04045), color));
}

vec2 cursorCenter(vec4 rect) {
    // OpenGL: xy is the top-left corner; the rectangle grows right and down.
    return rect.xy + rect.zw * vec2(0.5, -0.5);
}

float roundedRect(vec2 point, vec2 halfSize, float radius) {
    vec2 edge = abs(point) - halfSize + radius;
    return length(max(edge, 0.0)) + min(max(edge.x, edge.y), 0.0) - radius;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 terminal = texture(iChannel0, fragCoord / iResolution.xy);
    fragColor = terminal;

    // Hidden TUI cursors must stay hidden. Unfocused surfaces keep Ghostty's
    // native hollow cursor, whose opacity is independent of cursor-opacity.
    if (iFocus == 0 || iCursorVisible == 0 ||
        iCurrentCursor.z <= 0.0 || iCurrentCursor.w <= 0.0) {
        return;
    }

    vec2 current = cursorCenter(iCurrentCursor);
    vec2 previous = cursorCenter(iPreviousCursor);
    vec2 size = iCurrentCursor.zw;
    vec2 center = current;

    float cellW = max(1.0, iCurrentCursor.z);
    float dist = distance(current, previous);

    // Lock baseline on horizontal movements to eliminate sub-pixel vertical wobble
    if (abs(current.y - previous.y) < 2.0) {
        previous.y = current.y;
    }

    // Adaptive duration: 40ms for typing steps (prevents IME/rapid key stutter)
    // scaling up to 80ms for navigation jumps (word hops, arrows, mouse).
    float moveDuration = mix(TYPE_MOVE_SECONDS, JUMP_MOVE_SECONDS,
        clamp((dist - cellW * 1.5) / (cellW * 4.0), 0.0, 1.0));

    float age = max(0.0, iTime - iTimeCursorChange);
    float progress = clamp(age / moveDuration, 0.0, 1.0);
    float eased = 1.0 - pow(1.0 - progress, 3.0);

    // Animate single-character typing & word jumps. Avoid flying across the entire
    // window when entering a different pane, or using uninitialized history.
    bool hasPrevious = iPreviousCursor.z > 0.0 && iPreviousCursor.w > 0.0;
    float jumpLimit = 12.0 * max(iCurrentCursor.w, iPreviousCursor.w);
    if (hasPrevious && dist > 0.5 && dist < jumpLimit &&
        iTime - iTimeFocus > moveDuration) {
        center = mix(previous, current, eased);
        size = mix(iPreviousCursor.zw, size, eased);
    }

    vec2 halfSize = size * 0.5;
    vec2 point = fragCoord - center;
    // One terminal sample everywhere; only the caret region needs shape math.
    if (any(greaterThan(abs(point), halfSize + vec2(1.0)))) {
        return;
    }

    float radius = min(2.0, min(halfSize.x, halfSize.y));
    float edge = roundedRect(point, halfSize, radius);
    float coverage = 1.0 - smoothstep(-0.5, 0.5, edge);

    // Keep normal/insert/replace mode shapes distinct without covering text
    // with an opaque block. Bar and underline remain solid; blocks have an
    // outline and a faint fill, using the same theme color.
    if (iCurrentCursorStyle == CURSORSTYLE_BLOCK ||
        iCurrentCursorStyle == CURSORSTYLE_BLOCK_HOLLOW) {
        float outline = smoothstep(-1.5, -0.5, edge);
        float fill = iCurrentCursorStyle == CURSORSTYLE_BLOCK ? 0.15 : 0.0;
        coverage *= mix(fill, 1.0, outline);
    }

    // Smooth idle brightness replaces abrupt on/off blinking. Stay visible
    // while moving or typing; theme color is independent of native opacity.
    float phase = max(0.0, age - IDLE_DELAY) / PULSE_SECONDS;
    float pulse = 0.5 + 0.5 * cos(6.2831853 * phase);
    float opacity = mix(MIN_IDLE_OPACITY, 1.0, pulse);
    float focusFade = smoothstep(0.0, MOVE_SECONDS, max(0.0, iTime - iTimeFocus));
    float alpha = coverage * opacity * focusFade;

    // Ghostty's terminal texture uses premultiplied alpha. Preserve its
    // transparency outside the caret and use the runtime Noctalia color.
    vec3 color = toLinear(iCurrentCursorColor.rgb);
    fragColor = vec4(color * alpha + terminal.rgb * (1.0 - alpha),
        alpha + terminal.a * (1.0 - alpha));
}
