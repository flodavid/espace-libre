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

*Note:* If your version of Granite is 7.7 or later, accent color will be used for
bars and text style will be better for volume rows.

### Flatpak

At the root of the project:

```shell
flatpak-builder --install-deps-from=flathub --ccache flatpak-build io.github.flodavid.EspaceLibre.yml
flatpak build-bundle espaceLibreRepo io.github.flodavid.EspaceLibre.flatpak --runtime-repo=https://flatpak.elementary.io/repo.flatpakrepo io.github.flodavid.EspaceLibre daily
flatpak install io.github.flodavid.EspaceLibre.flatpak
```

### Ninja

In [meson.build](./meson.build), comment the line below `# For Flatpak only:`.

It's recommended to create a clean build environment.
Run `meson` to configure the build environment and then `ninja` to build

    meson setup "build" --prefix=/usr
    cd build
    ninja

#### Debug

After building

    G_MESSAGES_DEBUG=all src/espacelibre

#### Install

To install, use `ninja install`, then execute with `io.github.espacelibre`

    ninja install
    io.github.espacelibre

### Translations

To update translations files, go inside the *build* directory, then run:

    ninja io.github.flodavid.EspaceLibre-update-po