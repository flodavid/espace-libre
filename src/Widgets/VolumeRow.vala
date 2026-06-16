/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2026 flodavid
 */

public class EspaceLibre.VolumeRow : Granite.Bin {
    private VolumeEntry _partition_object = null;
    public VolumeEntry partition_object {
        get {
            return _partition_object;
        }

        set {
            if (_partition_object != null) {
                _partition_object.notify["fs-type"].disconnect (update_fs_type);
                _partition_object.notify["kb-size"].disconnect (update_sizes);
                _partition_object.notify["kb-used"].disconnect (update_sizes);
                _partition_object.notify["kb-avail"].disconnect (update_sizes);
                _partition_object.notify["device-type"].disconnect (update_cover_art);
            }

            _partition_object = value;

            if (_partition_object == null) {
                return;
            }

            update_all ();
            _partition_object.notify["fs-type"].connect (update_fs_type);
            _partition_object.notify["kb-size"].connect (update_sizes);
            _partition_object.notify["kb-used"].connect (update_sizes);
            _partition_object.notify["kb-avail"].connect (update_sizes);
            _partition_object.notify["device-type"].connect (update_cover_art);
        }
    }

    private Gtk.Label mount_point;
    private Gtk.Label volume_label;
    private Gtk.Image volume_image;
    private EspaceLibre.UsedSpaceBar space_bar;

    public VolumeRow (Gtk.SizeGroup labels_size_group) {
        volume_image = new Gtk.Image ();
        volume_image.height_request = 38;
        volume_image.width_request = 38;

        var aspect_frame = new Gtk.AspectFrame (0.5f, 0.5f, 1, false) {
            child = volume_image
        };

        volume_label = new Gtk.Label (null) {
            ellipsize = Pango.EllipsizeMode.START,
            hexpand = false,
            xalign = 0
        };
        labels_size_group.add_widget (volume_label);

        mount_point = new Gtk.Label (null) {
            ellipsize = Pango.EllipsizeMode.START,
            hexpand = false,
            xalign = 0
        };
        mount_point.add_css_class (Granite.CssClass.DIM);
        mount_point.add_css_class (Granite.CssClass.SMALL);
        labels_size_group.add_widget (mount_point);

        space_bar = new UsedSpaceBar ();

        var grid = new Gtk.Grid () {
            column_spacing = 12,
            margin_top = 6,
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 6
        };
        grid.attach (aspect_frame, 0, 0, 1, 2);
        grid.attach (volume_label, 1, 0);
        grid.attach (mount_point, 1, 1);
        grid.attach (space_bar, 2, 0, 1, 2);

        child = grid;
    }

    private void update_all () {
        volume_label.label = _partition_object.label;
        volume_label.label = _partition_object.label != null ? _partition_object.label : _partition_object.file_system;
        mount_point.label = _partition_object.mount_point;
        
        space_bar.is_system = _partition_object.is_system ();
        update_sizes ();
    }

    private void update_sizes () {
        space_bar.space_size = _partition_object.kb_size;
        space_bar.free_space = _partition_object.kb_avail;
        space_bar.used_space = _partition_object.kb_used;
    }

    private void update_cover_art () {
        var fs_volume = (VolumeEntry) _partition_object;
        if (fs_volume != null) {
            volume_image.paintable = fs_volume.get_texture ();
        }
    }

    private void update_fs_type (Object self, GLib.ParamSpec spec) {
        print ("update FS type of %s to: %s\n", _partition_object.label, _partition_object.fs_type);
    }
}
