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

```shell
flatpak-builder --install-deps-from=flathub --ccache flatpak-build fr.flodavid.EspaceLibre.yml
flatpak build-bundle espaceLibreRepo fr.flodavid.EspaceLibre.flatpak --runtime-repo=https://flatpak.elementary.io/repo.flatpakrepo fr.flodavid.EspaceLibre daily
flatpak install fr.flodavid.EspaceLibre.flatpak
```

### Ninja

In [meson.build](./meson.build), comment the line below `# For Flatpak only:`.

It's recommended to create a clean build environment.
Run `meson` to configure the build environment and then `ninja` to build

    meson setup "build" --prefix=/usr
    cd build
    ninja

To install, use `ninja install`, then execute with `fr.flodavid.espacelibre`

    ninja install
    fr.flodavid.espacelibre
