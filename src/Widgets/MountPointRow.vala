/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2026 flodavid
 */

public class EspaceLibre.MountPointRow : Gtk.Box {
    Gtk.Image dir_icon;
    Gtk.LinkButton mount_point;

    class construct {
        set_css_name ("mountPointRow");
    }

    construct {
        orientation = HORIZONTAL;
        spacing = 4;

        set_cursor (new Gdk.Cursor.from_name ("pointer", null));

        // Image        
        dir_icon = new Gtk.Image.from_icon_name ("folder") {
            pixel_size = 28,
        };
        dir_icon.add_css_class ("illustrated_directory");

        // Mount point with link
        mount_point = new Gtk.LinkButton (_("Not mounted")) {
            tooltip_text = _("Mount Point"),
        };

        append (dir_icon);
        append (mount_point);
    }

    public void update_mount_point (string? mount_point_location) {
        if (mount_point_location == null) return;

        mount_point.label = mount_point_location;
        mount_point.uri = "file://" + mount_point_location;
        if (mount_point_location == "/home") {
            dir_icon.icon_name = "user-home";
        } else {
            dir_icon.icon_name = "folder";
        }
    }
}
