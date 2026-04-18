/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2026 flodavid
 */

public class EspaceLibre.MainWindow : Gtk.ApplicationWindow {
    public const string ACTION_PREFIX = "win.";
    public const string ACTION_OPEN = "action-open";

    private DisksView disks_view;
    private DisksManager disks_manager;

    construct {
        // disks_view and selected_disk_view must be created before reading fstab and df command
        disks_view = new DisksView ();

        var end_window_controls = new Gtk.WindowControls (Gtk.PackType.END);

        var end_header = new Gtk.HeaderBar () {
            show_title_buttons = false,
            title_widget = new Gtk.Label ("")
        };
        end_header.add_css_class (Granite.STYLE_CLASS_FLAT);
        end_header.add_css_class (Granite.STYLE_CLASS_DEFAULT_DECORATION);
        end_header.pack_end (end_window_controls);

        var now_playing_view = new SelectedDiskView () {
            margin_top = 12,
            margin_end = 12,
            margin_bottom = 24,
            margin_start = 12,
            vexpand = true
        };

        var now_playing = new Gtk.Box (VERTICAL, 0);
        now_playing.append (end_header);
        now_playing.append (now_playing_view);

        var now_playing_handle = new Gtk.WindowHandle () {
            child = now_playing
        };

        var paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL) {
            start_child = disks_view,
            end_child = now_playing_handle,
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

        disks_manager = DisksManager.get_default ();
        disks_manager.readFSTAB ();
        disks_manager.readDF ();
    }

    public void start_refresh () {
        disks_manager.refresh ();
    }

}
