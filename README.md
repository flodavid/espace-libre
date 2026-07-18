# EspaceLibre

This is an alternative to KDiskFree, using Gnome's GTK and elementaryOS' Granite frameworks.

![Screenshot](data/screenshot.png?raw=true)

## Building, Testing, and Installation

You'll need the following dependencies:
* libadwaita-1 >=1.4.0
* granite-7 >=7.7.0
* gtk4
* meson
* valac

If your version of Granite is inferior to 7.7, in [meson.build](./meson.build),
comment the line above `# GRANITE < 7.7`, and uncomment the two lines below.

## Flatpak

`sudo flatpak-builder --install-deps-from=flathub --ccache --install flatpak-build fr.flodavid.espaceLibre.yml`

## Ninja

In [meson.build](./meson.build), uncomment the line below `# For Flatpak only:`.

It's recommended to create a clean build environment.
Run `meson` to configure the build environment and then `ninja` to build

    meson setup "build" --prefix=/usr
    cd build
    ninja

To install, use `ninja install`, then execute with `fr.flodavid.espaceLibre`

    ninja install
    fr.flodavid.espaceLibre
