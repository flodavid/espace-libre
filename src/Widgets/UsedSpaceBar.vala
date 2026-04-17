/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2026 flodavid
 */

public class EspaceLibre.UsedSpaceBar : Gtk.Grid {
    public uint64 space_size { get; set; }
    public uint64 used_space { get; set; }

    private uint64 _free_space;
    public uint64 free_space {
        get {
            return _free_space;
        }
        set {
            _free_space = value;

            if (space_size != 0) {
                free_space_fraction_label.label =
                "<span font-features='tnum'>%.1f</span>Go/".printf (_free_space / 1048576.0) +
                "<span font-features='tnum'>%.1f</span>Go".printf (space_size / 1048576.0);
                filled_bar.value = (space_size - _free_space) * 100.0 / space_size;
                free_space_percent_label.label = "%3u%%".printf ((uint)filled_bar.value);
            } else {
                filled_bar.value = 0;
            }
        }
    }

    private Gtk.Label free_space_fraction_label;
    private Gtk.LevelBar filled_bar;
    private Gtk.Label free_space_percent_label;

    construct {
        space_size = 0;

        column_spacing = 6;

        free_space_fraction_label = new Gtk.Label ("---Go/---Go") {
            valign = CENTER,
            ellipsize = Pango.EllipsizeMode.MIDDLE,
            use_markup = true
        };
        filled_bar = new Gtk.LevelBar () {
            valign = CENTER,
            hexpand = true,
            max_value = 100
        };
        free_space_percent_label = new Gtk.Label ("--%") {
            ellipsize = Pango.EllipsizeMode.MIDDLE,
            valign = CENTER
        };

        filled_bar.add_offset_value ("low", 90);
        filled_bar.add_offset_value ("high", 99);
        filled_bar.add_offset_value ("full", 100);

        attach (free_space_fraction_label, 0, 0);
        attach (filled_bar, 0, 1);
        attach (free_space_percent_label, 1, 1);
    }
}
