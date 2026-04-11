/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2026 flodavid
 */

public class EspaceLibre.DiskRow : Granite.Bin {
    private DiskEntry _partition_object = null;
    public DiskEntry partition_object {
        get {
            return _partition_object;
        }

        set {
            if (_partition_object != null) {
                _partition_object.notify["artist"].disconnect (update_mount_point);
                _partition_object.notify["title"].disconnect (update_disk_label);
                _partition_object.notify["texture"].disconnect (update_cover_art);
            }

            _partition_object = value;

            if (_partition_object == null) {
                return;
            }

            update_mount_point ();
            update_disk_label ();
            update_cover_art ();
            _partition_object.notify["artist"].connect (update_mount_point);
            _partition_object.notify["title"].connect (update_disk_label);
            _partition_object.notify["texture"].connect (update_cover_art);

        }
    }

    private static DisksManager playback_manager;

    private Gtk.Label mount_point;
    private Gtk.Label disk_label;
    private EspaceLibre.DiskImage album_image;

    static construct {
        playback_manager = DisksManager.get_default ();
    }

    construct {
        album_image = new EspaceLibre.DiskImage ();
        album_image.image.height_request = 32;
        album_image.image.width_request = 32;

        var aspect_frame = new Gtk.AspectFrame (0.5f, 0.5f, 1, false) {
            child = album_image
        };

        disk_label = new Gtk.Label (null) {
            ellipsize = Pango.EllipsizeMode.MIDDLE,
            hexpand = true,
            xalign = 0
        };

        mount_point = new Gtk.Label (null) {
            ellipsize = Pango.EllipsizeMode.MIDDLE,
            hexpand = true,
            xalign = 0
        };
        mount_point.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);
        mount_point.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);

        var grid = new Gtk.Grid () {
            column_spacing = 12,
            margin_top = 6,
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 6
        };
        grid.attach (aspect_frame, 0, 0, 1, 2);
        grid.attach (disk_label, 1, 0);
        grid.attach (mount_point, 1, 1);

        child = grid;
    }

    private void update_disk_label () {
        disk_label.label = _partition_object.name;
    }

    private void update_mount_point () {
        mount_point.label = _partition_object.mount_point;
    }

    private void update_cover_art () {
        album_image.image.paintable = _partition_object.texture;
    }
}
