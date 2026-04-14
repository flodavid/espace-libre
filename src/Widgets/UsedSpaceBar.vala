/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2026 flodavid
 */

public class EspaceLibre.UsedSpaceBar : Gtk.Box {
    public uint64 space_size { get; set; }

    private uint64 _used_space;
    public uint64 used_space {
        get {
            return _used_space;
        }
        set {
            _used_space = value;

            if (space_size != 0) {
                filled_bar.value = _used_space * 100.0 / space_size;
                free_space_label.label = "<span font-features='tnum'>%3u %</span>".printf ((uint)filled_bar.value);
            } else {
                filled_bar.value = 0;
            }
        }
    }

    private Gtk.Label free_space_label;
    private Gtk.LevelBar filled_bar;

    construct {
        space_size = 0;

        orientation = Gtk.Orientation.HORIZONTAL;
        spacing = 6;

        free_space_label = new Gtk.Label ("--%") {
            valign = CENTER,
            use_markup = true
        };

        filled_bar = new Gtk.LevelBar () {
            valign = CENTER,
            hexpand = true,
            max_value = 100
        };

        filled_bar.add_offset_value ("low", 90);
        filled_bar.add_offset_value ("high", 99);
        filled_bar.add_offset_value ("full", 100);

        append (filled_bar);
        append (free_space_label);
    }

    private void scale_value_changed () {
        if (space_size == 0) {
            filled_bar.value = 0;
            free_space_label.label = "  0%";
            return;
        }

        filled_bar.value = (double)_used_space * 100.0 / space_size;
        free_space_label.label = "<span font-features='tnum'>%3u %</span>".printf ((uint)filled_bar.value);
    }
}
