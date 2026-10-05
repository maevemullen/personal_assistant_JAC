"""Animated WebGL2 backdrop, ported from Originkit's "Mosaic Lens".

A flowing glow field is rendered at half resolution, then a second pass
pixelates it into tiles that sharpen into full detail around the pointer.
"""

import from "react" { useEffect }

glob _NL: str = chr(10);

# Tuning (Originkit preset: speed 100, size 153, tileSize 10, hover 83, reach 279).
glob MAX_DPR: float = 2.0;
glob SPEED: float = 0.7;   # animation rate; was 2.0 (Originkit speed 100)
glob SIZE: float = 1.53;
glob TILE: float = 10.0;
glob HOVER: float = 0.83;
glob REACH: float = 279.0;
glob BG: list[float] = [0.039, 0.027, 0.063];      # #0A0710
glob C1: list[float] = [1.0, 0.478, 0.239];        # #FF7A3D
glob C2: list[float] = [0.690, 0.302, 1.0];        # #B04DFF

glob VERT_SRC: str = _NL.join([
    "#version 300 es",
    "const vec2 P[3] = vec2[3](vec2(-1.0, -1.0), vec2(3.0, -1.0), vec2(-1.0, 3.0));",
    "void main() { gl_Position = vec4(P[gl_VertexID], 0.0, 1.0); }"
]);

glob FIELD_SRC: str = _NL.join([
    "#version 300 es",
    "precision highp float;",
    "uniform vec2 uRes;",
    "uniform float uTime;",
    "uniform vec3 uC1;",
    "uniform vec3 uC2;",
    "uniform float uSize;",
    "out vec4 o;",
    "const float LAYERS = 74.0;",
    "const float GAIN = 0.54;",
    "const vec2 CENTRE = vec2(-0.25, -0.56);",
    "const float TILT = -2.2;",
    "const float ZOOM = 1.05;",
    "const float THETA = 2.12;",
    "const float SHEAR = 0.956;",
    "const float SHRINK = 0.949;",
    "const vec2 WARP_FREQ = vec2(0.58, 2.8);",
    "const vec2 WARP_AMP = vec2(0.16, 0.034);",
    "const vec2 ASPECT = vec2(1.65, 0.22);",
    "const float OFFSET = 0.31;",
    "const float GLOW = 0.0021;",
    "const float SOFT = 0.0019;",
    "const float FALLOFF = 0.37;",
    "const float PHASE = 64.0;",
    "const float CYCLE = 0.16;",
    "const float HUE_TRAVEL = 2.0;",
    "mat2 rot(float a) { float c = cos(a), s = sin(a); return mat2(c, s, -s, c); }",
    "void main() {",
    "  vec2 pos = (gl_FragCoord.xy - 0.5 * uRes) / uRes.y;",
    "  pos = pos / uSize;",
    "  float t = uTime * 0.49 + PHASE;",
    "  float breath = (-sin(uTime * 0.735) + sin(uTime * 0.49 + 1.0)) * 0.25 + 0.5;",
    "  vec2 u = rot(TILT) * ((pos - CENTRE) * (ZOOM - breath * 0.085));",
    "  mat2 fold = mat2(cos(THETA), sin(THETA), -SHEAR, cos(THETA));",
    "  vec3 col = vec3(0.0);",
    "  for (float i = 1.0; i <= LAYERS; i += 1.0) {",
    "    u.x -= sin(u.y * WARP_FREQ.x + t + i * 0.007) * WARP_AMP.x;",
    "    u.y -= sin(u.x * WARP_FREQ.y - t + i * 0.02) * WARP_AMP.y;",
    "    u = fold * u * SHRINK;",
    "    vec2 q = (u - vec2(OFFSET + breath * 0.1, 0.0)) * ASPECT;",
    "    float g = GLOW / (dot(q, q) + SOFT) * (0.25 + breath * 0.4);",
    "    float r = length(u);",
    "    float k = sin(i * CYCLE + t * 1.2 + r * HUE_TRAVEL) * 0.5 + 0.5;",
    "    col += g * mix(uC1, uC2, k) * (0.62 + 0.5 * k) * exp2(-r * FALLOFF);",
    "  }",
    "  vec3 x = max(col * GAIN, 0.0);",
    "  col = (x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14);",
    "  col = pow(clamp(col, 0.0, 1.0), vec3(0.85, 0.92, 0.98));",
    "  col *= 1.0 - smoothstep(0.5, 1.6, length(pos)) * 0.07;",
    "  o = vec4(col, 1.0);",
    "}"
]);

glob FINISH_SRC: str = _NL.join([
    "#version 300 es",
    "precision highp float;",
    "uniform sampler2D uField;",
    "uniform vec2 uRes;",
    "uniform float uTime;",
    "uniform vec3 uBg;",
    "uniform vec2 uMouse;",
    "uniform float uOn;",
    "uniform float uReach;",
    "uniform float uTile;",
    "out vec4 o;",
    "const float TIERS = 4.0;",
    "float ign(vec2 p, float f) { p += 5.588238 * mod(f, 64.0); return fract(52.9829189 * fract(0.06711056 * p.x + 0.00583715 * p.y)); }",
    "vec3 scene(vec2 uv) { return texture(uField, clamp(uv, 0.0, 1.0)).rgb; }",
    "vec3 mosaic(vec2 frag, vec2 uv) {",
    "  float tier = 0.0;",
    "  if (uOn > 1e-4) {",
    "    vec2 cc = (floor(frag / uTile) + 0.5) * uTile;",
    "    vec2 d = (cc - uMouse) / uReach;",
    "    float w = uOn * exp(-dot(d, d));",
    "    tier = floor(min(w * (TIERS + 1.0), TIERS));",
    "  }",
    "  if (tier >= TIERS) return scene(uv);",
    "  float cell = uTile / exp2(tier);",
    "  vec2 c = (floor(frag / cell) + 0.5) * cell;",
    "  vec3 s = scene((c + cell * vec2(-0.25, -0.25)) / uRes) + scene((c + cell * vec2(0.25, -0.25)) / uRes)",
    "         + scene((c + cell * vec2(-0.25, 0.25)) / uRes) + scene((c + cell * vec2(0.25, 0.25)) / uRes);",
    "  return s * 0.25;",
    "}",
    "void main() {",
    "  vec2 frag = gl_FragCoord.xy;",
    "  vec3 L = max(mosaic(frag, frag / uRes), 0.0);",
    "  vec3 col = uBg + L * (1.0 - uBg);",
    "  col += (ign(frag, floor(uTime * 24.0)) - 0.5) / 255.0;",
    "  o = vec4(clamp(col, 0.0, 1.0), 1.0);",
    "}"
]);

def clamp_num(v: float, lo: float, hi: float) -> float {
    return lo if v < lo else (hi if v > hi else v);
}

def compile_shader(gl: any, kind: any, src: str, label: str) -> any {
    sh = gl.createShader(kind);
    gl.shaderSource(sh, src);
    gl.compileShader(sh);
    if not gl.getShaderParameter(sh, gl.COMPILE_STATUS) {
        console.error("MosaicBackground " + label + " shader:", gl.getShaderInfoLog(sh));
        gl.deleteShader(sh);
        return None;
    }
    return sh;
}

def link_program(gl: any, frag: str, label: str) -> any {
    vs = compile_shader(gl, gl.VERTEX_SHADER, VERT_SRC, label);
    fs = compile_shader(gl, gl.FRAGMENT_SHADER, frag, label);
    if not vs or not fs {
        return None;
    }
    prog = gl.createProgram();
    gl.attachShader(prog, vs);
    gl.attachShader(prog, fs);
    gl.linkProgram(prog);
    gl.deleteShader(vs);
    gl.deleteShader(fs);
    if not gl.getProgramParameter(prog, gl.LINK_STATUS) {
        console.error("MosaicBackground " + label + " link:", gl.getProgramInfoLog(prog));
        gl.deleteProgram(prog);
        return None;
    }
    return prog;
}

def uniforms(gl: any, prog: any, names: list[str]) -> dict[str, any] {
    out: dict[str, any] = {};
    for n in names {
        out[n] = gl.getUniformLocation(prog, n);
    }
    return out;
}

"""Allocate (or reallocate) the half-resolution texture the field renders into."""
def resize_target(gl: any, s: dict[str, any], w: float, h: float) {
    if w == s["fw"] and h == s["fh"] and s["tex"] {
        return;
    }
    for attempt in range(2) {
        if s["tex"] {
            gl.deleteTexture(s["tex"]);
        }
        half = s["half"];
        tex = gl.createTexture();
        s["tex"] = tex;
        gl.bindTexture(gl.TEXTURE_2D, tex);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
        gl.texImage2D(
            gl.TEXTURE_2D, 0, gl.RGBA16F if half else gl.RGBA8, w, h, 0,
            gl.RGBA, gl.HALF_FLOAT if half else gl.UNSIGNED_BYTE, None
        );
        gl.bindFramebuffer(gl.FRAMEBUFFER, s["fbo"]);
        gl.framebufferTexture2D(
            gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, tex, 0
        );
        ok = gl.checkFramebufferStatus(gl.FRAMEBUFFER) == gl.FRAMEBUFFER_COMPLETE;
        gl.bindFramebuffer(gl.FRAMEBUFFER, None);
        if ok or not half {
            break;
        }
        s["half"] = False;
    }
    s["fw"] = w;
    s["fh"] = h;
}

"""Start the render loop on `canvas`; returns a cleanup function."""
def start_mosaic(canvas: any) -> any {
    noop = lambda { };
    gl = canvas.getContext(
        "webgl2",
        {"antialias": False, "alpha": False, "depth": False, "stencil": False}
    );
    if not gl {
        console.warn("MosaicBackground: WebGL2 unavailable, using flat background");
        return noop;
    }
    field = link_program(gl, FIELD_SRC, "field");
    finish = link_program(gl, FINISH_SRC, "finish");
    if not field or not finish {
        return noop;
    }
    uf = uniforms(gl, field, ["uRes", "uTime", "uC1", "uC2", "uSize"]);
    un = uniforms(
        gl, finish,
        ["uField", "uRes", "uTime", "uBg", "uMouse", "uOn", "uReach", "uTile"]
    );
    vao = gl.createVertexArray();
    gl.bindVertexArray(vao);

    reduce_motion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;  # jac:ignore[E1030]
    speed = 0.0 if reduce_motion else SPEED;

    # Mutable loop state lives in one dict so the nested callbacks can update it.
    s: dict[str, any] = {
        "fbo": gl.createFramebuffer(),
        "tex": None,
        "fw": 0,
        "fh": 0,
        "half": bool(gl.getExtension("EXT_color_buffer_float")),
        "tx": 0.0,
        "ty": 0.0,
        "inside": False,
        "mx": 0.0,
        "my": 0.0,
        "on": 0.0,
        "raf": 0,
        "last": -1.0,
        "clock": 0.0
    };

    def read_pointer(e: any) {
        s["tx"] = e.clientX;
        s["ty"] = e.clientY;
        s["inside"] = True;
    }

    def leave_window(e: any) {
        if not e.relatedTarget {
            s["inside"] = False;
        }
    }

    def render(now: float) {
        s["raf"] = requestAnimationFrame(render);
        dt = 0.0 if s["last"] < 0 else clamp_num((now - s["last"]) / 1000.0, 0.0, 0.05);
        s["last"] = now;
        s["clock"] = (s["clock"] + dt * speed) % 3600.0;

        dpr = Math.min(window.devicePixelRatio or 1, MAX_DPR);
        cw = canvas.clientWidth or 1200;
        ch = canvas.clientHeight or 800;
        bw = Math.max(1, Math.round(cw * dpr));
        bh = Math.max(1, Math.round(ch * dpr));
        if canvas.width != bw or canvas.height != bh {
            canvas.width = bw;
            canvas.height = bh;
        }
        resize_target(
            gl, s, Math.max(1, Math.round(bw / 2)), Math.max(1, Math.round(bh / 2))
        );

        # Ease the lens in/out and let it trail the pointer slightly.
        present = 1.0 if s["inside"] else 0.0;
        if present > 0 and s["on"] < 0.02 {
            s["mx"] = s["tx"];
            s["my"] = s["ty"];
        }
        s["on"] = s["on"] + (present - s["on"]) * (1 - Math.exp(-dt * 5));
        k = 1 - Math.exp(-dt * 16);
        s["mx"] = s["mx"] + (s["tx"] - s["mx"]) * k;
        s["my"] = s["my"] + (s["ty"] - s["my"]) * k;
        sx = bw / cw;
        sy = bh / ch;

        gl.bindFramebuffer(gl.FRAMEBUFFER, s["fbo"]);
        gl.viewport(0, 0, s["fw"], s["fh"]);
        gl.useProgram(field);
        gl.uniform2f(uf["uRes"], s["fw"], s["fh"]);
        gl.uniform1f(uf["uTime"], s["clock"]);
        gl.uniform3f(uf["uC1"], C1[0], C1[1], C1[2]);
        gl.uniform3f(uf["uC2"], C2[0], C2[1], C2[2]);
        gl.uniform1f(uf["uSize"], SIZE);
        gl.drawArrays(gl.TRIANGLES, 0, 3);

        gl.bindFramebuffer(gl.FRAMEBUFFER, None);
        gl.viewport(0, 0, bw, bh);
        gl.useProgram(finish);
        gl.activeTexture(gl.TEXTURE0);
        gl.bindTexture(gl.TEXTURE_2D, s["tex"]);
        gl.uniform1i(un["uField"], 0);
        gl.uniform2f(un["uRes"], bw, bh);
        gl.uniform1f(un["uTime"], s["clock"]);
        gl.uniform3f(un["uBg"], BG[0], BG[1], BG[2]);
        gl.uniform2f(un["uMouse"], s["mx"] * sx, bh - s["my"] * sy);
        gl.uniform1f(un["uOn"], s["on"] * HOVER);
        gl.uniform1f(un["uReach"], REACH * sy);
        gl.uniform1f(un["uTile"], Math.max(1, Math.round(TILE * dpr)));
        gl.drawArrays(gl.TRIANGLES, 0, 3);
    }

    window.addEventListener("pointermove", read_pointer, {"passive": True});
    window.addEventListener("pointerdown", read_pointer, {"passive": True});
    document.addEventListener("pointerout", leave_window);
    s["raf"] = requestAnimationFrame(render);

    return lambda {
        cancelAnimationFrame(s["raf"]);
        window.removeEventListener("pointermove", read_pointer);
        window.removeEventListener("pointerdown", read_pointer);
        document.removeEventListener("pointerout", leave_window);
        if s["tex"] {
            gl.deleteTexture(s["tex"]);
        }
        gl.deleteFramebuffer(s["fbo"]);
        gl.deleteVertexArray(vao);
        gl.deleteProgram(field);
        gl.deleteProgram(finish);
    };
}

def:pub MosaicBackground -> JsxElement {
    has canvasRef: Ref[HTMLCanvasElement] = Ref();

    # Manual effect: the render loop and listeners must be released on unmount.
    useEffect(
        lambda -> any {
            if not canvasRef.current {
                return lambda { };
            }
            return start_mosaic(canvasRef.current);
        },
        []
    );

    <div className="mosaic-bg" aria-hidden="true">
        <canvas ref={canvasRef} className="mosaic-canvas"/>
    </div>
}
