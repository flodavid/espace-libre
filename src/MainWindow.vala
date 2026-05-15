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
        disks_manager = DisksManager.get_default ();

        var end_window_controls = new Gtk.WindowControls (Gtk.PackType.END);

        var end_header = new Gtk.HeaderBar () {
            show_title_buttons = false,
            title_widget = new Gtk.Label ("")
        };
        end_header.add_css_class (Granite.STYLE_CLASS_FLAT);
        end_header.add_css_class (Granite.STYLE_CLASS_DEFAULT_DECORATION);
        end_header.pack_end (end_window_controls);

        var selected_disk_view = new SelectedDiskView () {
            margin_top = 12,
            margin_end = 12,
            margin_bottom = 24,
            margin_start = 12,
            vexpand = true
        };

        var selected_disk = new Gtk.Box (VERTICAL, 0);
        selected_disk.append (end_header);
        selected_disk.append (selected_disk_view);

        var selected_disk_handle = new Gtk.WindowHandle () {
            child = selected_disk
        };
        var selected_disk_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT,
            child = selected_disk_handle
        };

        var paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL) {
            start_child = disks_view,
            resize_end_child = false,
            shrink_end_child = false,
            shrink_start_child = false
        };
        disks_manager.notify["current-disk"].connect (() => {
            if (disks_manager.current_disk != null) {
                paned.end_child = selected_disk_revealer;
                selected_disk_revealer.reveal_child = true;
            } else {
                paned.end_child = null;
                selected_disk_revealer.reveal_child = false;
            }
        });

        child = paned;

        // We need to hide the title area for the split headerbar
        var null_title = new Gtk.Grid () {
            visible = false
        };
        set_titlebar (null_title);

        var settings = new Settings ("fr.flodavid.espaceLibre");
        settings.bind ("pane-position", paned, "position", SettingsBindFlags.DEFAULT);

        disks_manager.readFSTAB ();
        disks_manager.readDF ();
    }

    public void start_refresh () {
        disks_manager.refresh ();
    }

}
