/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2026 flodavid
 */

public class EspaceLibre.DiskEntry : Object {
    public string file_system_type { get; construct; }
    public Gdk.Texture? texture { get; private set; default = null; }
    public string mount_point { get; set; }
    public string format_type { get; set; }
    public string mount_options { get; set; }
    public string dump { get; set; }
    public string pass { get; set; }
    public string name { get; set; }
    public string uuid { get; set; }
    public bool mounted { get; set; }
    public int64 total_space { get; set; default = 0; }

    public DiskEntry (string _file_system_type, string _mount_point, string _format_type, string _mount_options,
        string dump, string pass)
    {
        Object (file_system_type: _file_system_type, mount_point: _mount_point, format_type: _format_type,
            mount_options: _mount_options, dump: dump, pass: pass);
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
