/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2026 flodavid
 */

public class EspaceLibre.VolumesView : Granite.Bin {

    private Granite.Placeholder volume_list_placeholder;
    private Gtk.Button refresh_button;
    private Gtk.ListView volumes_listview;
    private Gtk.ScrolledWindow scrolled;
    private Gtk.SignalListItemFactory factory;
    private Gtk.Stack volumes_stack;
    private VolumesManager volumes_manager;

    construct {
        volumes_manager = VolumesManager.get_default ();

        var start_window_controls = new Gtk.WindowControls (Gtk.PackType.START);

        refresh_button = new Gtk.Button.from_icon_name ("media-playlist-repeat-symbolic") {
            action_name = Application.ACTION_PREFIX + Application.ACTION_REFRESH,
            tooltip_text = _("Refresh")
        };
        refresh_button.add_css_class ("highlighted");

        var end_window_controls = new Gtk.WindowControls (Gtk.PackType.END);

        var volume_list_header = new Gtk.HeaderBar () {
            show_title_buttons = false,
        };
        volume_list_header.add_css_class (Granite.STYLE_CLASS_DEFAULT_DECORATION);
        volume_list_header.pack_start (start_window_controls);
        volume_list_header.pack_end (end_window_controls);
        volume_list_header.pack_end (refresh_button);

        volume_list_placeholder = new Granite.Placeholder (_("No volume found")) {
            description = _("Mounted volumes should appear here"),
            icon = new ThemedIcon ("playlist-queue")
        };

        var selection_model = new Gtk.SingleSelection (volumes_manager.volumes) {
            autoselect = false
        };
        selection_model.items_changed.connect (volumes_manager.on_items_changed);

        volumes_manager.automatically_selected_item.connect ((position) => {
            debug ("force item selection at position: %u", position);
            selection_model.set_selected (position);
        });

        var labels_size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
        factory = new Gtk.SignalListItemFactory ();
        factory.setup.connect ((obj) => {
            var list_item = (Gtk.ListItem) obj;
            list_item.child = new VolumeRow (labels_size_group);
            //  labels_size_group.add_widget (list_item.child);
            if (!volumes_manager.has_items ()) {
                warning ("no items. selected: %u", selection_model.selected);
                volumes_manager.current_volume = (VolumeEntry) selection_model.selected_item;
            }
        });

        factory.bind.connect ((obj) => {
            var list_item = (Gtk.ListItem) obj;
            var row = (VolumeRow) list_item.child;
            // Do not bind again, values do not update, entries are removed and recreated
            if (row.partition_object == null) {
                row.partition_object = (VolumeEntry) list_item.item;
            }
        });

        volumes_listview = new Gtk.ListView (selection_model, factory) {
            hexpand = true,
            vexpand = true,
            show_separators = true
        };

        scrolled = new Gtk.ScrolledWindow () {
            child = volumes_listview
        };

        volumes_stack = new Gtk.Stack ();
        volumes_stack.add_child (volume_list_placeholder);
        volumes_stack.add_child (scrolled);

        var volume_list = new Adw.ToolbarView () {
            bottom_bar_style = RAISED,
            content = volumes_stack
        };
        volume_list.add_css_class (Granite.STYLE_CLASS_VIEW);
        volume_list.add_top_bar (volume_list_header);

        var error_toast = new Granite.Toast ("");

        var volume_list_overlay = new Gtk.Overlay () {
            child = volume_list
        };
        volume_list_overlay.add_overlay (error_toast);

        var volume_list_handle = new Gtk.WindowHandle () {
            child = volume_list_overlay
        };

        child = volume_list_handle;

        /* SIGNALS */

        volumes_manager.volumes.items_changed.connect (() => {
            if (volumes_manager.has_items ()) {
                volumes_stack.visible_child = scrolled;
                return;
            }

            info ("volumes attribute is null/empty");
            volumes_stack.visible_child = volume_list_placeholder;
        });

        volumes_manager.invalids_found.connect ((count) => {
            error_toast.title = ngettext (
                "%d invalid volume was not added to the queue",
                "%d invalid volumes were not added to the queue",
                count).printf (count);
            error_toast.send_notification ();
        });

        selection_model.selection_changed.connect (() => {
            if (selection_model.get_selected_item () != null) {
                volume_list_header.remove (end_window_controls);
            } else {
                volume_list_header.pack_end (end_window_controls);
            }

            // Logic to unselect
            //  bool before = disks_manager.has_items;
            //  if (disks_manager.has_items) {
            //      if (!before) {
            //          warning("had no items, but now has some");
            //          disks_manager.current_disk = (DiskEntry) disks_manager.disks.get_item (0);
            //      } else {
            //          warning("still some items");
            //      }
            //  } else {
            //      if (before) {
            //          warning("no more items");
            //          disks_manager.current_disk = null;
            //      } else {
            //          warning("still no items");
            //      }
            //  }

            volumes_manager.current_volume = (VolumeEntry)selection_model.selected_item;
        });
    }
}
