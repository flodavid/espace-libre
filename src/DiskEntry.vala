/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2026 flodavid
 */

public class EspaceLibre.DiskEntry : Object {
    public string file_system_type { get; construct; }
    public Gdk.Texture? texture { get; private set; default = null; }
    public string mount_point { get; set; }
    public string format_type { get; construct; }
    public string mount_options { get; construct; }
    public string dump { get; construct; }
    public string pass { get; construct; }
    public string name { get; set; }
    public string uuid { get; set; }
    public bool mounted { get; set; }
    public int64 total_space { get; set; default = 0; }

    public DiskEntry (string file_system_type, string mount_point, string format_type, string mount_options,
        string dump, string pass)
    {
        Object (file_system_type: file_system_type, mount_point: mount_point, format_type: format_type,
            mount_options: mount_options, dump: dump, pass: pass);
    }

    construct {
        name = file_system_type;
        mounted = false;
    }

    public void update_metadata (string info) {
        // TODO read data from fstab line
        total_space = (int64) 0;

        string _name = "";
        //  tag_list.get_string (Gst.Tags.TITLE, out _name);
        if (_name != null) {
            name = _name;
        }
    }

    public static bool equal_func (DiskEntry a, DiskEntry b) {
        return (a.file_system_type == b.file_system_type);
    }
}
