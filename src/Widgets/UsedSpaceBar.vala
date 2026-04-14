/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2026 flodavid
 */

public class EspaceLibre.UsedSpaceBar : Gtk.Box {
    private int64 _available_space;
    public int64 available_space {
        get {
            return _available_space;
        }
        set {
            int64 space = value;
            if (space < 0) {
                space = 0;
            }

            _available_space = space;

            free_space_label.label = "<span font-features='tnum'>%d</span>".printf (
                (int) (space / 1024)
            );
        }
    }

    private int64 _used_space;
    public int64 used_space {
        get {
            return _used_space;
        }
        set {
            int64 position = value;
            if (position < 0) {
                position = 0;
            }

            _used_space = position;

            if (position != 0) {
                filled.set_fraction ((double) 1 / available_space * position);
            } else {
                filled.set_fraction (0);
            }
        }
    }

    private Gtk.Label free_space_label;
    private Gtk.ProgressBar filled;

    construct {
        orientation = Gtk.Orientation.HORIZONTAL;
        spacing = 6;

        free_space_label = new Gtk.Label ("--/--") {
            valign = CENTER,
            use_markup = true
        };

        filled = new Gtk.ProgressBar () {
            valign = CENTER,
            hexpand = true
        };

        append (filled);
        append (free_space_label);
    }

    private void scale_value_changed () {
        free_space_label.label = "<span font-features='tnum'>%d</span>".printf (
            (int) (_available_space / 1024)
        );
    }
}
