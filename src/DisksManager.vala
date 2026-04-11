/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2026 flodavid
 */

public class EspaceLibre.DisksManager : Object {
    public DiskEntry? current_audio { get; set; default = null; }
    public ListStore disks_liststore { get; private set; }
    public bool has_items { get; private set; }
    public uint n_items {
        get {
            return disks_liststore != null ? disks_liststore.get_n_items () : 0;
        }
    }
    public int64 used_space { get; private set; }
    public signal void invalids_found (int count);

    private static GLib.Once<DisksManager> instance;
    public static unowned DisksManager get_default () {
        return instance.once (() => { return new DisksManager (); });
    }

    private uint progress_timer = 0;
    private Settings settings;


    private bool next_by_eos = false;

    private SimpleAction refresh_action;

    private DisksManager () {}

    construct {
        settings = new Settings ("fr.flodavid.espaceLibre");
        disks_liststore = new ListStore (typeof (DiskEntry));

        disks_liststore.items_changed.connect (on_items_changed);

        notify["current-audio"].connect (on_selected_disk_changed);

        settings = new Settings ("fr.flodavid.espaceLibre");

        refresh_action = new SimpleAction (Application.ACTION_REFRESH, null);
        refresh_action.activate.connect (refresh);
        refresh_action.set_enabled (true);

        unowned var app = GLib.Application.get_default ();
        app.add_action (refresh_action);
    }

    public void show_disks (DiskEntry[] disks) {
        foreach (unowned var disk in disks) {
            disks_liststore.append (disk);
        }
    }

    private void refresh () {
        var temp_list = new ListStore (typeof (DiskEntry));

        uint position = -1;

        while (disks_liststore.get_n_items () > 0) {
            var random_position = Random.int_range (0, (int32) disks_liststore.get_n_items ());

            temp_list.append (disks_liststore.get_item (random_position));
            disks_liststore.remove (random_position);
        }

        for (int i = 0; i < temp_list.get_n_items (); i++) {
            disks_liststore.append (temp_list.get_item (i));
        }
    }

    private void on_items_changed () {
        has_items = disks_liststore.get_n_items () > 0;
    }

    private void on_selected_disk_changed () {
        // TODO implement select disk change
    }
}
