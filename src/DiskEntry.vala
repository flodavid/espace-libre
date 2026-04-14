/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2026 flodavid
 */

public class EspaceLibre.DiskEntry : Object {
    public Gdk.Texture? texture { get; private set; default = null; } // TOOD replace by enum for disk type
    
    public string file_system { get; construct; }
    public string mount_point { get; set; }
    public string fs_type { get; set; }
    public string mount_options { get; construct; }
    public string dump { get; construct; }
    public string pass { get; construct; }
    public string name { get; set; }
    public string uuid { get; set; }
    public bool mounted { get; set; }
    public int64 total_space { get; set; default = 0; }

    public DiskEntry (string file_system, string mount_point, string format_type, string mount_options,
        string dump, string pass)
    {
        Object (file_system: file_system, mount_point: mount_point, fs_type: format_type,
            mount_options: mount_options, dump: dump, pass: pass);
    }

    construct {
        name = file_system;
        mounted = false;
    }
}
