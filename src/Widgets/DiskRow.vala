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
                _partition_object.notify["mount-point"].disconnect (update_mount_point);
                _partition_object.notify["name"].disconnect (update_disk_label);
                _partition_object.notify["texture"].disconnect (update_cover_art);
            }

            _partition_object = value;

            if (_partition_object == null) {
                return;
            }

            update_mount_point ();
            update_disk_label ();
            update_cover_art ();
            _partition_object.notify["mount-point"].connect (update_mount_point);
            _partition_object.notify["name"].connect (update_disk_label);
            _partition_object.notify["texture"].connect (update_cover_art);

        }
    }

    private static DisksManager playback_manager;

    private Gtk.Label mount_point;
    private Gtk.Label disk_label;
    private EspaceLibre.DiskImage disk_image;
    private EspaceLibre.UsedSpaceBar space_bar;
    private Gtk.SizeGroup labels_size_group;

    static construct {
        playback_manager = DisksManager.get_default ();
    }

    public DiskRow (Gtk.SizeGroup _labels_size_group) {
        labels_size_group = _labels_size_group;
        
        disk_image = new EspaceLibre.DiskImage ();
        disk_image.image.height_request = 32;
        disk_image.image.width_request = 32;

        var aspect_frame = new Gtk.AspectFrame (0.5f, 0.5f, 1, false) {
            child = disk_image
        };

        disk_label = new Gtk.Label (null) {
            ellipsize = Pango.EllipsizeMode.MIDDLE,
            hexpand = false,
            xalign = 0
        };
        labels_size_group.add_widget (disk_label);

        mount_point = new Gtk.Label (null) {
            ellipsize = Pango.EllipsizeMode.MIDDLE,
            hexpand = false,
            xalign = 0
        };
        mount_point.add_css_class (Granite.CssClass.DIM);
        mount_point.add_css_class (Granite.CssClass.SMALL);

        space_bar = new UsedSpaceBar ();

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
        grid.attach (space_bar, 2, 0, 1, 2);

        child = grid;
    }

    private void update_disk_label () {
        disk_label.label = _partition_object.name;
    }

    private void update_mount_point () {
        mount_point.label = _partition_object.mount_point;
    }

    private void update_cover_art () {
        disk_image.image.paintable = _partition_object.texture;
    }
}
