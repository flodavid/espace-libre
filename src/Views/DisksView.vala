/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2026 flodavid
 */

public class EspaceLibre.DisksView : Granite.Bin {
    private Granite.Placeholder disk_list_placeholder;
    private Gtk.Button refresh_button;
    private Gtk.ListView disks_listview;
    private Gtk.ScrolledWindow scrolled;
    private Gtk.SingleSelection selection_model;
    private Gtk.Stack disks_stack;
    private Settings settings;
    private GLib.ListStore disks;
    private DisksManager disks_manager;
    private Gtk.SignalListItemFactory factory;

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


        disks = new GLib.ListStore (typeof (DiskEntry));
        readFSTAB ();

        var selection_model = new Gtk.SingleSelection (disks) {
            autoselect = true
        };
        selection_model.items_changed.connect (on_items_changed);

        factory = new Gtk.SignalListItemFactory ();
        factory.setup.connect ((obj) => {
            var list_item = (Gtk.ListItem) obj;
            list_item.child = new DiskRow ();
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

        on_items_changed ();

        settings = new Settings ("fr.flodavid.espaceLibre");

        disks_manager.disks_liststore.items_changed.connect (() => {
            if (disks_manager.n_items == 0) {
                disks_stack.visible_child = disk_list_placeholder;
            }
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

    /**
     * tries to figure out the possibly mounted fs
     */
    private void readFSTAB () {
        string fstab_content;
        FileUtils.get_contents ("/etc/fstab", out fstab_content);

        if (fstab_content != null && fstab_content != "") {
            string[] lines = fstab_content.split ("\n");
            foreach (string line in lines) {
                if (line.length > 0 && line.get_char(0) != '#') {
                    // not empty or commented out by '#'
                    warning("GOT: [%s]", line);
                    
                    // Replace tabs and multiple spaces by single spaces
                    string clean_line = line.replace ("\t", " ");;
                    do {
                        line = clean_line;
                        clean_line = line.replace ("  ", " ");
                    } while (line != clean_line);

                    string[] columns = clean_line.split (" ");

                    // Remove LABEL= and UUID=
                    if (columns[0] != null && columns[1] != null && columns[2] != null && columns[3] != null
                        && columns[4] != null && columns[5] != null)
                    {
                        string uuid = "";

                        string file_system = columns[0];
                        if (columns[0].has_prefix ("LABEL=")) {
                            file_system = columns[0].split ("=")[1];
                        // Find the partition corresponding to the UUID
                        } else {
                            if (columns[0].has_prefix ("UUID=")) {
                                if (GLib.FileUtils.test ("/dev/disk/by-uuid/", GLib.FileTest.IS_DIR)) {
                                    uuid = columns[0].split ("=")[1];
                                    if (GLib.FileUtils.test ("/dev/disk/by-uuid/" + uuid, GLib.FileTest.IS_SYMLINK)) {
                                        info("UUID disk [%s] exists in UUID dir", uuid);
                                        file_system = Posix.realpath ("/dev/disk/by-uuid/" + uuid);
                                    } else {
                                        warning ("Invalid UUID or non existing device: %s", uuid);
                                        uuid = "";
                                    }
                                } else {
                                    debug ("/dev/disk/by-uuid/ does not exists, so we cannot match the UUID");
                                }
                            }
                        }

                        warning("Partition identifier: [%s]", file_system);
                        var disk = new DiskEntry (file_system, columns[1], columns[2], columns[3], columns[4], columns[5]);
                        disk.uuid = uuid;

                        disks.append(disk);
                    }

                    //  if ((disk->deviceName() != QLatin1String("none")) && (disk->fsType() != QLatin1String("swap")) && (disk->fsType() != QLatin1String("sysfs"))
                    //      && (disk->fsType() != QLatin1String("rootfs")) && (disk->fsType() != QLatin1String("tmpfs")) && (disk->fsType() != QLatin1String("debugfs"))
                    //      && (disk->fsType() != QLatin1String("devtmpfs")) && (disk->mountPoint() != QLatin1String("/dev/swap"))
                    //      && (disk->mountPoint() != QLatin1String("/dev/pts")) && (disk->mountPoint() != QLatin1String("/dev/shm"))
                    //      && (!disk->mountPoint().startsWith(QLatin1String("/sys/"))) && (!disk->mountPoint().startsWith(QLatin1String("/proc/")))) {
                    //      replaceDeviceEntry(disk);
                    //  }
                }
            }
        }

        //  loadSettings(); // to get the mountCommands
    }

    private void on_items_changed () {
        if (selection_model.n_items > 0) {
            disks_stack.visible_child = scrolled;
            return;
        }

        disks_stack.visible_child = disk_list_placeholder;
    }
}
