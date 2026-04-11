# EspaceLibre

![Screenshot](data/screenshot.png?raw=true)

## Building, Testing, and Installation

You'll need the following dependencies:
* libadwaita-1 >=1.4.0
* granite-7 >=7.6.0
* gtk4
* meson
* valac

It's recommended to create a clean build environment. Run `meson` to configure the build environment and then `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`, then execute with `fr.flodavid.espaceLibre`

    ninja install
    fr.flodavid.espaceLibre
