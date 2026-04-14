/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2026 flodavid
 */

public class EspaceLibre.SelectedDiskView : Gtk.Box {
    construct {
        var disk_label = new Gtk.Label (_("Disk")) {
            ellipsize = Pango.EllipsizeMode.MIDDLE
        };
        disk_label.add_css_class (Granite.STYLE_CLASS_H3_LABEL);

        var mount_point = new Gtk.Label (_("Not mounted")) {
            ellipsize = Pango.EllipsizeMode.MIDDLE
        };

        var mount_point_revealer = new Gtk.Revealer () {
            child = mount_point
        };

        var info_grid = new Gtk.Grid () {
            halign = Gtk.Align.CENTER
        };
        info_grid.attach (disk_label, 0, 0);
        info_grid.attach (mount_point_revealer, 0, 1);

        var used_bar = new EspaceLibre.UsedSpaceBar ();

        var grid = new Gtk.Grid () {
            column_spacing = 12,
            row_spacing = 24,
            valign = Gtk.Align.START,
            vexpand = true
        };
        grid.attach (info_grid, 0, 1, 3);
        grid.attach (used_bar, 0, 2, 3);

        orientation = Gtk.Orientation.VERTICAL;
        spacing = 24;
        append (grid);

        var playback_manager = DisksManager.get_default ();

        playback_manager.notify["current-audio"].connect (() => {
            if (playback_manager.current_disk != null) {
                playback_manager.current_disk.bind_property ("mount-point", mount_point, "label", BindingFlags.SYNC_CREATE);
                playback_manager.current_disk.bind_property ("name", disk_label, "label", BindingFlags.SYNC_CREATE);
                playback_manager.current_disk.bind_property ("duration", used_bar, "playback-duration", BindingFlags.SYNC_CREATE);
            } else {
                mount_point.label = _("Not mounted");
                disk_label.label = _("Disk");
                used_bar.space_size = 0;
                used_bar.used_space = 0;
            }
        });

        mount_point.notify["label"].connect (() => {
            mount_point_revealer.reveal_child = mount_point.label != "";
        });
    }
}
