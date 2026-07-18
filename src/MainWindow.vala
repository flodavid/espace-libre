/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2026 flodavid
 */

public class EspaceLibre.MainWindow : Gtk.ApplicationWindow {
    public const string ACTION_PREFIX = "win.";
    public const string ACTION_OPEN = "action-open";

    private VolumesView volumes_view;
    private Gtk.Paned paned;
    private Gtk.Revealer selected_volume_revealer;

    construct {
        // volumes_view and selected_volume_view must be created before reading fstab and df command
        volumes_view = new VolumesView ();

        var end_window_controls = new Gtk.WindowControls (Gtk.PackType.END);

        var end_header = new Gtk.HeaderBar () {
            show_title_buttons = false,
            title_widget = new Gtk.Label ("")
        };
        end_header.add_css_class (Granite.STYLE_CLASS_FLAT);
        end_header.add_css_class (Granite.STYLE_CLASS_DEFAULT_DECORATION);
        end_header.pack_end (end_window_controls);

        var selected_volume_view = new SelectedVolumeView (this) {
            margin_top = 12,
            margin_end = 12,
            margin_bottom = 24,
            margin_start = 12,
            vexpand = true
        };

        var selected_volume = new Gtk.Box (VERTICAL, 0);
        selected_volume.append (end_header);
        selected_volume.append (selected_volume_view);

        var selected_volume_handle = new Gtk.WindowHandle () {
            child = selected_volume
        };
        selected_volume_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT,
            child = selected_volume_handle
        };

        paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL) {
            start_child = volumes_view,
            resize_end_child = false,
            shrink_end_child = false,
            shrink_start_child = false
        };

        child = paned;

        // We need to hide the title area for the split headerbar
        var null_title = new Gtk.Grid () {
            visible = false
        };
        set_titlebar (null_title);

        var settings = new Settings ("fr.flodavid.espaceLibre");
        settings.bind ("pane-position", paned, "position", SettingsBindFlags.DEFAULT);
    }

    public void reveal_current_volume_pane () {
        paned.end_child = selected_volume_revealer;
        selected_volume_revealer.reveal_child = true;
    }

    public void hide_current_volume_pane () {
        paned.end_child = null;
        selected_volume_revealer.reveal_child = false;
    }
}
