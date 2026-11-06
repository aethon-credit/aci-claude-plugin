#!/usr/bin/env bash
# Builds the OpenAI Agent Plugins ZIP for ACI Risk Indicators.
#
#   scripts/build-openai-zip.sh
#
# Assembles openai/plugin.json, openai/mcp.json, openai/assets/ and the shared
# skills/ into dist/aci-risk-indicators-openai-<version>.zip, with those four at
# the ZIP root. Before writing anything it checks the manifests against the
# submission rules (developers.openai.com/plugins/deploy/submission) and exits
# non-zero on the first failure. Python 3 does the checks and the zipping, so
# no zip binary is needed.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PY="${PYTHON:-}"
if [ -z "$PY" ]; then
  for c in python3 python; do
    if command -v "$c" >/dev/null 2>&1 && "$c" -c 'import sys; sys.exit(sys.version_info < (3, 8))' 2>/dev/null; then
      PY="$c"; break
    fi
  done
fi
[ -n "$PY" ] || { echo "build-openai-zip: Python 3.8+ is required" >&2; exit 1; }

exec "$PY" -I - "$ROOT" <<'PYEOF'
import json, os, re, struct, sys, zipfile
from xml.etree import ElementTree

root = sys.argv[1]
src = os.path.join(root, "openai")
errors = []

def fail(msg):
    errors.append(msg)

def load(name):
    path = os.path.join(src, name)
    if not os.path.isfile(path):
        sys.exit(f"build-openai-zip: missing {os.path.relpath(path, root)}")
    with open(path, encoding="utf-8") as f:
        return json.load(f)

plugin = load("plugin.json")
mcp = load("mcp.json")

# ---- plugin.json ----
if not plugin.get("$schema", "").startswith("https://agent-plugins.org/schemas/"):
    fail("plugin.json: $schema must be the Agent Plugins schema URL")
name = plugin.get("name", "")
if not (isinstance(name, str) and 0 < len(name) <= 64 and re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*", name)):
    fail(f"plugin.json: name {name!r} must be 1-64 lowercase letters/digits with single hyphens")
version = plugin.get("version", "")
if not re.fullmatch(r"\d+\.\d+\.\d+", str(version)):
    fail(f"plugin.json: version {version!r} must be MAJOR.MINOR.PATCH")

ui = plugin.get("extensions", {}).get("com.openai", {}).get("interface")
if not isinstance(ui, dict):
    sys.exit("build-openai-zip: plugin.json has no extensions.com.openai.interface")

def text(key, limit, required=True):
    v = ui.get(key)
    if v is None:
        if required:
            fail(f"interface.{key} is required")
        return
    if not isinstance(v, str) or not v.strip():
        fail(f"interface.{key} must be a non-empty string")
    elif len(v) > limit:
        fail(f"interface.{key} is {len(v)} characters; the limit is {limit}")

text("displayName", 30)
text("shortDescription", 30)
text("longDescription", 4000)
text("developerName", 80)
text("category", 80)

for key in ("websiteURL", "supportURL", "privacyPolicyURL", "termsOfServiceURL"):
    v = ui.get(key)
    if not (isinstance(v, str) and v.startswith("https://") and len(v) <= 1024):
        fail(f"interface.{key} must be an HTTPS URL of at most 1024 characters")

caps = ui.get("capabilities", [])
if not (isinstance(caps, list) and len(caps) <= 20 and all(isinstance(c, str) and 0 < len(c) <= 120 for c in caps)):
    fail("interface.capabilities must be at most 20 strings of at most 120 characters")
prompts = ui.get("defaultPrompt", [])
if not (isinstance(prompts, list) and len(prompts) <= 3 and all(isinstance(p, str) and 0 < len(p) <= 128 for p in prompts)):
    fail("interface.defaultPrompt must be at most 3 strings of at most 128 characters")

def luminance(hex_):
    def ch(c):
        c = c / 255
        return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    r, g, b = (int(hex_[i:i + 2], 16) for i in (1, 3, 5))
    return 0.2126 * ch(r) + 0.7152 * ch(g) + 0.0722 * ch(b)

def contrast(a, b):
    la, lb = sorted((luminance(a), luminance(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)

for key, bg in (("brandColor", "#FFFFFF"), ("brandColorDark", "#212121")):
    v = ui.get(key)
    if v is None:
        continue
    if not (isinstance(v, str) and re.fullmatch(r"#[0-9A-Fa-f]{6}", v)):
        fail(f"interface.{key} must be #RRGGBB")
    elif contrast(v, bg) < 2:
        fail(f"interface.{key} {v} has {contrast(v, bg):.2f}:1 contrast against {bg}; at least 2:1 is required")

if "hooks" in plugin:
    fail("plugin.json: hooks are not accepted")

# ---- every ./ path in the manifests must exist inside openai/ ----
assets = []
def walk(node, where):
    if isinstance(node, dict):
        for k, v in node.items():
            walk(v, f"{where}.{k}")
    elif isinstance(node, list):
        for i, v in enumerate(node):
            walk(v, f"{where}[{i}]")
    elif isinstance(node, str) and node.startswith("./"):
        rel = node[2:]
        if ".." in rel.split("/") or not os.path.exists(os.path.join(src, rel)):
            fail(f"{where}: {node} does not exist in openai/")
        else:
            assets.append((where, rel))
walk(plugin, "plugin.json")
walk(mcp, "mcp.json")
if not ui.get("logo"):
    fail("interface.logo is required (a square image of at least 48x48)")

# ---- images: square, >= 48px, <= 4096 raster, <= 5 MiB ----
def image_size(path):
    with open(path, "rb") as f:
        head = f.read(64)
    if head[:8] == b"\x89PNG\r\n\x1a\n":
        return struct.unpack(">II", head[16:24])
    if head[:4] == b"RIFF" and head[8:12] == b"WEBP":
        with open(path, "rb") as f:
            d = f.read(40)
        if d[12:16] == b"VP8X":
            return 1 + int.from_bytes(d[24:27], "little"), 1 + int.from_bytes(d[27:30], "little")
        if d[12:16] == b"VP8 ":
            return struct.unpack("<H", d[26:28])[0] & 0x3FFF, struct.unpack("<H", d[28:30])[0] & 0x3FFF
        if d[12:16] == b"VP8L":
            b = int.from_bytes(d[21:25], "little")
            return (b & 0x3FFF) + 1, ((b >> 14) & 0x3FFF) + 1
    if head[:2] == b"\xff\xd8":
        with open(path, "rb") as f:
            f.read(2)
            while True:
                m = f.read(2)
                if len(m) < 2 or m[0] != 0xFF:
                    break
                if m[1] in (0xC0, 0xC1, 0xC2):
                    f.read(3)
                    h, w = struct.unpack(">HH", f.read(4))
                    return w, h
                f.read(struct.unpack(">H", f.read(2))[0] - 2)
    if path.lower().endswith(".svg"):
        el = ElementTree.parse(path).getroot()
        vb = el.get("viewBox")
        if vb:
            _, _, w, h = (float(x) for x in re.split(r"[\s,]+", vb.strip()))
            return w, h, "svg"
        num = lambda s: float(re.match(r"[\d.]+", s or "").group(0)) if re.match(r"[\d.]+", s or "") else None
        return num(el.get("width")), num(el.get("height")), "svg"
    return None

ICON_KEYS = ("logo", "logoDark", "composerIcon", "composerIconDark")
for where, rel in assets:
    if where.rsplit(".", 1)[-1] not in ICON_KEYS:
        continue
    path = os.path.join(src, rel)
    if os.path.getsize(path) > 5 * 1024 * 1024:
        fail(f"{where}: {rel} is over 5 MiB")
    size = image_size(path)
    if not size or size[0] is None or size[1] is None:
        fail(f"{where}: {rel} is not a PNG, JPEG, WebP or SVG with readable dimensions")
        continue
    w, h = size[0], size[1]
    if w != h:
        fail(f"{where}: {rel} is {w}x{h}; it must be square")
    if min(w, h) < 48:
        fail(f"{where}: {rel} is {w}x{h}; the minimum is 48x48")
    if len(size) == 2 and max(w, h) > 4096:
        fail(f"{where}: {rel} is {w}x{h}; raster images are limited to 4096px")

# ---- mcp.json ----
servers = mcp.get("mcpServers")
if not isinstance(servers, dict) or not servers:
    fail("mcp.json: mcpServers must name at least one server")
else:
    for sid, s in servers.items():
        if s.get("type") != "streamable-http":
            fail(f"mcp.json: {sid}.type must be streamable-http")
        if not str(s.get("url", "")).startswith("https://"):
            fail(f"mcp.json: {sid}.url must be HTTPS")
        if s.get("headers"):
            fail(f"mcp.json: {sid} must not set headers")
blob = json.dumps(mcp).lower()
for banned in ("clientsecret", "client_secret\"", "\"clientid\"", "bearer", "api_key\""):
    if banned in blob:
        fail(f"mcp.json: contains {banned.strip(chr(34))!r}; no secrets or credentials belong in the package")

# ---- skills ----
skills = os.path.join(root, "skills")
skill_files = []
for dirpath, _, files in os.walk(skills):
    for fn in files:
        skill_files.append(os.path.join(dirpath, fn))
if not any(f.endswith(os.sep + "SKILL.md") for f in skill_files):
    fail("skills/: no SKILL.md found")
if "review" in plugin and "test_credentials" in json.dumps(plugin.get("review")):
    fail("plugin.json: test_credentials must not be in the package")

if errors:
    print("build-openai-zip: validation failed:", file=sys.stderr)
    for e in errors:
        print(f"  - {e}", file=sys.stderr)
    sys.exit(1)

# ---- write the ZIP ----
dist = os.path.join(root, "dist")
os.makedirs(dist, exist_ok=True)
out = os.path.join(dist, f"{name}-openai-{version}.zip")
entries = [("plugin.json", os.path.join(src, "plugin.json")), ("mcp.json", os.path.join(src, "mcp.json"))]
for dirpath, _, files in os.walk(os.path.join(src, "assets")):
    for fn in files:
        p = os.path.join(dirpath, fn)
        entries.append((os.path.relpath(p, src).replace(os.sep, "/"), p))
for p in skill_files:
    entries.append((os.path.relpath(p, root).replace(os.sep, "/"), p))
entries.sort()
tmp = out + ".tmp"
with zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED) as z:
    for arc, p in entries:
        info = zipfile.ZipInfo(arc, date_time=(2026, 1, 1, 0, 0, 0))
        info.compress_type = zipfile.ZIP_DEFLATED
        info.external_attr = 0o644 << 16
        with open(p, "rb") as f:
            z.writestr(info, f.read())
os.replace(tmp, out)
print(f"build-openai-zip: wrote {os.path.relpath(out, root)} ({len(entries)} files)")
for arc, _ in entries:
    print(f"  {arc}")
PYEOF
