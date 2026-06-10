/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2026 flodavid
 */

public class EspaceLibre.UsedSpaceBar : Gtk.Grid {
    private static double GIGA = 1048576.0;

    private uint64 _space_size;
    public uint64 space_size {
        get {
            return _space_size;
        }
        set {
            _space_size = value;

            free_space_fraction_label.visible = true;
            if (_free_space != 0) {
                set_fractions_and_filled_bar ();
            } else {
                free_space_fraction_label.label = "<span font-features='tnum'>%.1f</span>".printf (_free_space / GIGA)+_("Go");
            }
        }
    }

    public uint64 used_space { get; set; }

    private uint64 _free_space;
    public uint64 free_space {
        get {
            return _free_space;
        }
        set {
            _free_space = value;

            if (_space_size != 0) {
                set_fractions_and_filled_bar ();
            } else {
                filled_bar.visible = false;
                free_space_percent_label.visible = false;
            }
        }
    }

    private bool _is_system;
    public bool is_system {
        get {
            return _is_system;
        }
        set {
            _is_system = value;
            update_offset_limits ();
        }
    }

    private Gtk.Label free_space_fraction_label;
    private Gtk.LevelBar filled_bar;
    private Gtk.Label free_space_percent_label;

    construct {
        _space_size = 0;
        _is_system = false;

        column_spacing = 6;

        free_space_fraction_label = new Gtk.Label ("---Go") {
            visible = false,
            valign = CENTER,
            hexpand = true,
            ellipsize = Pango.EllipsizeMode.START,
            use_markup = true
        };
        filled_bar = new Gtk.LevelBar () {
            visible = false,
            valign = CENTER,
            hexpand = true
        };
        // Avoid using accent color if it is too to red/orange
        if (Granite.Settings.get_default ().accent_color.red < 0.9) {
            filled_bar.add_css_class ("colored_bar");
        }
        free_space_percent_label = new Gtk.Label ("--%") {
            visible = false,
            ellipsize = Pango.EllipsizeMode.MIDDLE,
            valign = CENTER
        };

        attach (free_space_fraction_label, 0, 0);
        attach (filled_bar, 0, 1);
        attach (free_space_percent_label, 1, 1);
    }

    private void set_fractions_and_filled_bar () {
        filled_bar.visible = true;
        free_space_percent_label.visible = true;

        free_space_fraction_label.label = _("Free: ") +
            "<span font-features='tnum'>%.1f</span>".printf (_free_space / GIGA) + _("Go") + "/" +
            "<span font-features='tnum'>%.1f</span>".printf (_space_size / GIGA) + _("Go");
        var free_percent = _free_space * 100.0 / _space_size;
        free_space_percent_label.label = "%.0f%%".printf (free_percent);

        filled_bar.value = _space_size - _free_space;
        filled_bar.max_value = _space_size;
        update_offset_limits ();
    }

    private void update_offset_limits () {
        if (space_size <= 0.0) {
            return;
        }

        if (_is_system) {
            filled_bar.add_offset_value ("low", double.max(0.80 * space_size, space_size - 3 * GIGA));
            filled_bar.add_offset_value ("high", double.max(0.95 * space_size, space_size - 1 * GIGA));
        } else {
            filled_bar.add_offset_value ("low", 0.95 * space_size);
            filled_bar.add_offset_value ("high", 0.99 * space_size);
        }
        filled_bar.add_offset_value ("full", space_size);
    }
}
