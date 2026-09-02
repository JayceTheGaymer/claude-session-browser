#!/usr/bin/env bash
# Builds a Linux AppImage for Claude Session Browser.
#
# Bundles pywebview + pystray and their pure-Python dependencies -- safe
# regardless of the host's Python version. Everything else (GTK3,
# WebKitGTK, PyGObject, pycairo, python-xlib, Pillow, dbus-fast) is
# expected on the host system; see PREREQUISITES.md. Bundling those isn't
# safely possible: PyGObject/pycairo/python-xlib bind directly to host
# native libraries, and Pillow/dbus-fast ship Python-ABI-tagged compiled
# extensions that would break against whatever Python version the host
# actually has (bundling one matched to this build machine's Python could
# simply fail to import on a host running a different version).
#
# Requires appimagetool on PATH (AUR: appimagetool-bin) and a working pip.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"
APPDIR="${BUILD_DIR}/AppDir"
APP_SHARE="${APPDIR}/usr/share/claude-session-browser"

command -v appimagetool >/dev/null 2>&1 || {
    echo "appimagetool not found on PATH (AUR: appimagetool-bin)." >&2
    exit 1
}

# Many distros (Arch included, PEP 668) don't ship a system pip at all.
# --target installs work the same regardless of which pip runs them, so
# fall back to the project's own dev venv if there's no system pip.
if command -v pip >/dev/null 2>&1; then
    PIP=(pip)
elif command -v pip3 >/dev/null 2>&1; then
    PIP=(pip3)
elif python3 -m pip --version >/dev/null 2>&1; then
    PIP=(python3 -m pip)
elif [ -x "${REPO_ROOT}/.venv/bin/pip" ]; then
    PIP=("${REPO_ROOT}/.venv/bin/pip")
else
    echo "No usable pip found (checked pip, pip3, python3 -m pip, ${REPO_ROOT}/.venv/bin/pip)." >&2
    echo "Create a venv first: python3 -m venv ${REPO_ROOT}/.venv" >&2
    exit 1
fi

rm -rf "${BUILD_DIR}"
mkdir -p "${APP_SHARE}/vendor"

# App source files. csb_updater.py / build.bat / setup.iss deliberately
# not copied -- Windows-only packaging tooling, irrelevant here.
cp "${REPO_ROOT}/claude_sessions.py" \
   "${REPO_ROOT}/clawdmeter.py" \
   "${REPO_ROOT}/i18n.py" \
   "${REPO_ROOT}/clawd_sprites.py" \
   "${REPO_ROOT}/LICENSE" \
   "${APP_SHARE}/"
# _resource() (used for the tray icon) looks next to claude_sessions.py
# itself, not the AppDir root -- needs its own copy here too, separate
# from the one placed at the AppDir root for the .desktop file's Icon=.
cp "${REPO_ROOT}/docs/logo.png" "${APP_SHARE}/logo.png"

# --no-deps: pystray would otherwise also pull in Pillow/python-xlib, and
# bleak would pull in dbus-fast -- both host-provided, see header comment.
# bleak itself is pure Python and safe to bundle; only its dependency isn't.
"${PIP[@]}" install --no-deps --target "${APP_SHARE}/vendor" \
    pywebview pystray bleak bottle proxy_tools typing_extensions six

cp "${SCRIPT_DIR}/AppRun" "${APPDIR}/AppRun"
chmod +x "${APPDIR}/AppRun"
cp "${SCRIPT_DIR}/claude-session-browser.desktop" "${APPDIR}/"
cp "${REPO_ROOT}/docs/logo.png" "${APPDIR}/claude-session-browser.png"

OUT="${BUILD_DIR}/ClaudeSessionBrowser-x86_64.AppImage"
# AppRun is a plain shell script, not a binary -- appimagetool normally
# infers the architecture by inspecting an ELF binary in the AppDir, which
# there isn't one of here, so it has to be told explicitly.
ARCH=x86_64 appimagetool "${APPDIR}" "${OUT}"

echo "Built: ${OUT}"
