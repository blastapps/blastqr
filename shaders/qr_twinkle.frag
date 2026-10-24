#version 460 core

#include <flutter/runtime_effect.glsl>

// The home screen's backdrop: a wall of QR codes whose dark modules fade in
// and out, each at its own pace, like twinkling. A few soft patches of
// "light" drift slowly around the box; under them more modules come on, so
// the twinkle gathers and wanders rather than being even everywhere.
//
// Drawn in one colour (the tint) over transparent, across the whole box,
// faded towards the top. Everything is procedural: no texture reads, no loops.
//
// All lengths are logical pixels.

// The size of the box.
uniform vec2 uSize;
// The size of one QR module.
uniform float uCell;
// One device pixel, for antialiasing the modules' edges.
uniform float uPixel;
// Where the animation is in its cycle, 0 to 1, round and round. Every motion
// below repeats a whole number of times per cycle, so the loop has no seam.
uniform float uTime;
// The tint, straight (not premultiplied), with the overall opacity in alpha.
uniform vec4 uColor;
// Where the backdrop starts fading in from nothing, and where it reaches full
// strength, measured down from the top; so it blends into the app bar with
// no edge where the bar ends.
uniform float uFadeStart;
uniform float uFadeEnd;

out vec4 fragColor;

const float TAU = 6.2831853;

// Modules per QR code along each side (a version 4 code).
const float kTile = 33.0;

// The fewest and most times a module twinkles in one cycle. Whole numbers,
// so the loop has no seam.
const float kTwinkleMin = 8.0;
const float kTwinkleMax = 16.0;

// A number from 0 to 1, the same every time for the same [p] and unrelated
// from one [p] to the next. Arithmetic only, which holds up better than the
// sin() hash at mediump on mobile GPUs.
float hash(vec2 p) {
  vec3 p3 = fract(vec3(p.xyx) * 0.1031);
  p3 += dot(p3, p3.yzx + 33.33);
  return fract((p3.x + p3.y) * p3.z);
}

// One drifting patch of light at [uv], following a slow Lissajous path.
float blob(vec2 uv, vec2 centre, vec2 reach, vec2 rate, vec2 phase,
    float radius) {
  vec2 c = centre + reach * sin(TAU * (uTime * rate + phase));
  vec2 d = (uv - c) * vec2(uSize.x / uSize.y, 1.0);
  return exp(-dot(d, d) / (radius * radius));
}

// How lit the box is at [uv] (0 to 1 across the box), 0 to about 1.
float light(vec2 uv) {
  float l = 0.05;
  l += blob(uv, vec2(0.30, 0.60), vec2(0.30, 0.35), vec2(1.0, 2.0),
      vec2(0.00, 0.25), 0.20);
  l += blob(uv, vec2(0.70, 0.40), vec2(0.30, 0.35), vec2(2.0, 1.0),
      vec2(0.40, 0.10), 0.18);
  l += 0.8 * blob(uv, vec2(0.50, 0.50), vec2(0.45, 0.40), vec2(1.0, 3.0),
      vec2(0.70, 0.55), 0.16);
  return clamp(l, 0.0, 1.0);
}

// Whether the module at [m] (within its code) is the start of a finder or
// alignment pattern's block: each takes up 4 x 4 modules, and is drawn
// inside it on modules half the size, so the patterns are half as large as
// in a real code and don't dominate the wall.
bool inPatternBlock(vec2 m) {
  float far = kTile - 4.0;
  bool nearX = m.x < 4.0;
  bool farX = m.x >= far;
  bool nearY = m.y < 4.0;
  bool farY = m.y >= far;
  if ((nearX || farX) && (nearY || farY) && !(farX && farY)) return true;
  // The alignment pattern's block, just inside the fourth corner.
  return all(greaterThanEqual(m, vec2(kTile - 5.0)))
      && all(lessThanEqual(m, vec2(kTile - 2.0)));
}

// Whether the half-size module at [f] (within its code, on the half-size
// grid) is dark in a finder or alignment pattern: 1 for dark, 0 for light.
// Only asked inside a pattern block.
float pattern(vec2 f) {
  float far = 2.0 * kTile - 7.0;
  bool nearX = f.x < 8.0;
  bool farX = f.x >= far - 1.0;
  bool nearY = f.y < 8.0;
  bool farY = f.y >= far - 1.0;
  if ((nearX || farX) && (nearY || farY) && !(farX && farY)) {
    // A finder pattern: 7 x 7, with a light separator on its inner sides.
    vec2 g = vec2(farX ? f.x - far : f.x, farY ? f.y - far : f.y);
    if (g.x < 0.0 || g.y < 0.0 || g.x > 6.0 || g.y > 6.0) return 0.0;
    float r = max(abs(g.x - 3.0), abs(g.y - 3.0));
    return (r == 3.0 || r <= 1.0) ? 1.0 : 0.0;
  }
  // The alignment pattern: 5 x 5, with light around it to fill its block.
  float r = max(abs(f.x - far), abs(f.y - far));
  return (r == 2.0 || r == 0.0) ? 1.0 : 0.0;
}

void main() {
  vec2 p = FlutterFragCoord().xy;
  if (p.y <= uFadeStart) {
    fragColor = vec4(0.0);
    return;
  }

  // The module this pixel falls in, and where in it, -0.5 to 0.5.
  vec2 index = floor(p / uCell);
  vec2 q = p / uCell - index - 0.5;

  // The light at the module's middle, so a module comes on as a whole.
  float l = light((index + 0.5) * uCell / uSize);

  // Which code the module is in, with every other row of codes shifted
  // half a code along like bricks, and each code flipped its own way, so
  // the finder patterns don't line up into a grid.
  float row = floor(index.y / kTile);
  vec2 shifted = vec2(index.x + mod(row, 2.0) * floor(kTile * 0.5), index.y);
  vec2 code = floor(shifted / kTile);
  vec2 m = shifted - code * kTile;
  // Which half of the module this pixel is in, for the half-size patterns.
  vec2 half_ = step(0.0, q);
  float flip = hash(code + 3.7);
  if (flip < 0.5) {
    m.x = kTile - 1.0 - m.x;
    half_.x = 1.0 - half_.x;
  }
  if (fract(flip * 7.0) < 0.5) {
    m.y = kTile - 1.0 - m.y;
    half_.y = 1.0 - half_.y;
  }

  float on;
  float cell = uCell;
  if (inPatternBlock(m)) {
    // Finder and alignment patterns don't twinkle; they show only where
    // the light is brightest, so the wall still reads as QR codes without
    // them dominating it. Drawn on the half-size grid.
    on = pattern(m * 2.0 + half_) * smoothstep(0.4, 0.9, l);
    cell = 0.5 * uCell;
    q = fract(p / cell) - 0.5;
  } else {
    // A data module: a slow wave of its own, which it rides over a
    // threshold set by the light — high where it is dark, so none come on,
    // lower where it is light, so about half do, as in a real code. The
    // wide band makes each fade in and out smoothly rather than switch.
    float rate = floor(mix(kTwinkleMin, kTwinkleMax + 1.0, hash(index + 17.0)));
    float wave = 0.5 + 0.5 * sin(TAU * (uTime * rate + hash(index)));
    float threshold = mix(1.1, 0.55, l);
    on = smoothstep(threshold - 0.2, threshold + 0.2, wave);
  }
  if (on <= 0.0) {
    fragColor = vec4(0.0);
    return;
  }

  // The module grows a little as it comes on; fully on, it just overlaps
  // its neighbours so lit runs of modules show no seams.
  float extent = mix(0.3, 0.5 + uPixel / cell, on);
  float d = (max(abs(q.x), abs(q.y)) - extent) * cell;
  float coverage = clamp(0.5 - d / uPixel, 0.0, 1.0);

  float fade = smoothstep(uFadeStart, uFadeEnd, p.y);

  float a = uColor.a * fade * on * coverage;
  fragColor = vec4(uColor.rgb * a, a);
}
