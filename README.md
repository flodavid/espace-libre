# EspaceLibre

This is an alternative to KDiskFree, using Gnome's GTK and elementaryOS' Granite
frameworks.

![Screenshot](data/screenshot.png?raw=true)

## Building, Testing, and Installation

You'll need the following dependencies:
* libadwaita-1 >=1.4.0
* granite-7 >=7.6.0
* gtk4
* meson
* valac

If your version of Granite is 7.7 or later you can activate accent color usage
for bars and better text style for volume rows. In [meson.build](./meson.build),
uncomment the line above `# GRANITE < 7.7`, and comment the two lines below.

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
