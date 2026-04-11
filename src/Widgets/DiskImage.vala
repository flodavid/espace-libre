/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2026 flodavid
 */

public class EspaceLibre.DiskImage : Gtk.Grid {
    public Gtk.Image image;

    class construct {
        set_css_name ("album");
    }

    construct {
        image = new Gtk.Image ();

        add_css_class (Granite.STYLE_CLASS_CARD);
        add_css_class (Granite.STYLE_CLASS_ROUNDED);
        overflow = Gtk.Overflow.HIDDEN;
        attach (image, 0, 0);
    }
}
