# Linux prerequisites

The AppImage bundles `pywebview` and `pystray` (pure Python, safe regardless
of your system's Python version). It relies on your system for everything
that binds to native libraries or ships Python-version-specific compiled
extensions, since bundling those risks breaking against whatever Python
version your system actually has:

- **GTK3 / WebKitGTK** — the actual UI toolkit and web-rendering engine.
- **PyGObject** (`gi`), **pycairo** (`cairo`), **python-xlib** (`Xlib`) —
  bind directly to GTK/Cairo/X11 native libraries, so a bundled copy would
  need to match your system's exact library versions anyway.
- **Pillow** (`PIL`) — used for sprite/icon handling; ships compiled
  extensions tied to a specific Python ABI.
- **dbus-fast** — used by `bleak` for the optional Clawdmeter Bluetooth
  link; same ABI concern as Pillow. Only needed if you use a Clawdmeter.

## Arch / CachyOS

```bash
sudo pacman -S webkit2gtk-4.1 python-gobject python-cairo python-xlib python-pillow python-dbus-fast
```

## Other distros

Package names vary. Look for your distro's equivalents of:
`webkit2gtk` (4.1 or later), `python3-gobject` (or `pygobject`),
`python3-cairo` (or `pycairo`), `python3-xlib`, `python3-pillow`,
`python3-dbus-fast`.

## Also useful, not required to launch

- `bluetoothctl` (from `bluez-utils` on Arch) — needed for the Clawdmeter
  Bluetooth device picker; the app degrades gracefully without it (you can
  still set a device address manually).
- A terminal emulator the app already knows about — checks `$TERMINAL` then
  falls through a list of common ones (kitty, foot, gnome-terminal, konsole,
  xfce4-terminal, tilix, terminator, alacritty, xterm, urxvt). One of these
  is virtually always present on a desktop Linux install already.

## Why not bundle everything?

See the header comment in `build-appimage.sh`. Short version: GTK3 +
WebKitGTK + GObject-Introspection are a well-known hard case for portable
Linux packaging in general (not specific to this project or to AppImage),
and Pillow/dbus-fast's compiled extensions are tied to a Python ABI version
that a single bundled build can't safely guarantee will match an arbitrary
host. A fully self-contained build (matching how the Windows version is
built via PyInstaller) is possible but a substantially bigger undertaking —
see the project plan doc for the open follow-up item.
