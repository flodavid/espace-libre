/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2026 flodavid
 */

public class EspaceLibre.DisksView : Granite.Bin {

    private Granite.Placeholder disk_list_placeholder;
    private Gtk.Button refresh_button;
    private Gtk.ListView disks_listview;
    private Gtk.ScrolledWindow scrolled;
    private Gtk.SignalListItemFactory factory;
    private Gtk.Stack disks_stack;
    private DisksManager disks_manager;

    construct {
        disks_manager = DisksManager.get_default ();

        var start_window_controls = new Gtk.WindowControls (Gtk.PackType.START);

        refresh_button = new Gtk.Button.from_icon_name ("media-playlist-repeat-symbolic") {
            action_name = Application.ACTION_PREFIX + Application.ACTION_REFRESH,
            tooltip_text = _("Refresh")
        };

        var disk_list_header = new Gtk.HeaderBar () {
            show_title_buttons = false,
        };
        disk_list_header.add_css_class (Granite.STYLE_CLASS_DEFAULT_DECORATION);
        disk_list_header.pack_start (start_window_controls);
        disk_list_header.pack_end (refresh_button);

        disk_list_placeholder = new Granite.Placeholder (_("No disk found")) {
            description = _("Mounted disks should appear here"),
            icon = new ThemedIcon ("playlist-queue")
        };

        var selection_model = new Gtk.SingleSelection (disks_manager.disks) {
            autoselect = true
        };
        selection_model.items_changed.connect (disks_manager.on_items_changed);

        var labels_size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
        factory = new Gtk.SignalListItemFactory ();
        factory.setup.connect ((obj) => {
            var list_item = (Gtk.ListItem) obj;
            list_item.child = new DiskRow (labels_size_group);
        });

        factory.bind.connect ((obj) => {
            var list_item = (Gtk.ListItem) obj;
            ((DiskRow) list_item.child).partition_object = (DiskEntry) list_item.item;
        });

        disks_listview = new Gtk.ListView (selection_model, factory) {
            single_click_activate = true,
            hexpand = true,
            vexpand = true
        };

        scrolled = new Gtk.ScrolledWindow () {
            child = disks_listview
        };

        disks_stack = new Gtk.Stack ();
        disks_stack.add_child (disk_list_placeholder);
        disks_stack.add_child (scrolled);

        var disk_list = new Adw.ToolbarView () {
            bottom_bar_style = RAISED,
            content = disks_stack
        };
        disk_list.add_css_class (Granite.STYLE_CLASS_VIEW);
        disk_list.add_top_bar (disk_list_header);

        var error_toast = new Granite.Toast ("");

        var disk_list_overlay = new Gtk.Overlay () {
            child = disk_list
        };
        disk_list_overlay.add_overlay (error_toast);

        var disk_list_handle = new Gtk.WindowHandle () {
            child = disk_list_overlay
        };

        child = disk_list_handle;

        disks_manager.disks.items_changed.connect (() => {
            if (disks_manager.has_items) {
                disks_stack.visible_child = scrolled;
                return;
            }

            warning("disks attribute is null/empty");
            disks_stack.visible_child = disk_list_placeholder;
        });

        disks_manager.invalids_found.connect ((count) => {
            error_toast.title = ngettext (
                "%d invalid disk was not added to the queue",
                "%d invalid disks were not added to the queue",
                count).printf (count);
            error_toast.send_notification ();
        });

        disks_listview.activate.connect ((index) => {
            disks_manager.current_disk = (DiskEntry) selection_model.get_item (index);
        });
    }
}

