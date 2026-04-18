/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2026 flodavid
 */

public class EspaceLibre.DisksManager : Object {
    public static unowned DisksManager get_default () {
        return instance.once (() => { return new DisksManager (); });
    }

    public DiskEntry? current_disk { get; set; default = null; }
    public ListStore disks { get; private set; }
    public bool has_items { get; private set; }
    public uint n_items {
        get {
            return disks != null ? disks.n_items : 0;
        }
    }
    
    public signal void invalids_found (int count);

    private static string Blank = " ";
    private static GLib.Once<DisksManager> instance;

    private bool readingDFStdErrOut;
    private DisksManager () {}

    construct {
        readingDFStdErrOut = false;
        disks = new ListStore (typeof (DiskEntry));

        disks.items_changed.connect (on_items_changed);
    }

    public void show_disk (DiskEntry disk) {
        disks.append (disk);
    }

    /**
     * tries to figure out the possibly mounted fs
     */
    public void readFSTAB () {
        string fstab_content;
        FileUtils.get_contents ("/etc/fstab", out fstab_content);

        if (fstab_content != null && fstab_content != "") {
            string[] lines = fstab_content.split ("\n");
            foreach (string line in lines) {
                warning("GOT: [%s]", line);

                line = line._strip ();
                // Treat lines not empty or commented out by '#'
                if (line.length > 0 && line.get_char(0) != '#') {

                    var columns = string_to_array (line);

                    // Remove LABEL= and UUID=
                    if (columns[0] != null && columns[1] != null && columns[2] != null && columns[3] != null
                        && columns[4] != null && columns[5] != null)
                    {
                        string file_system = columns[0];
                        string label = null;
                        string uuid = "";

                        if (columns[0].has_prefix ("LABEL=")) {
                            if (GLib.FileUtils.test ("/dev/disk/by-label/", GLib.FileTest.IS_DIR)) {
                                label = columns[0].split ("=")[1];
                                if (GLib.FileUtils.test ("/dev/disk/by-label/" + label, GLib.FileTest.IS_SYMLINK)) {
                                    info("Disk with label [%s] exists in Label dir", label);
                                    file_system = Posix.realpath ("/dev/disk/by-label/" + label);
                                } else {
                                    warning ("Invalid Label or non existing device: %s", label);
                                }
                            } else {
                                debug ("/dev/disk/by-label/ does not exists, so we cannot match the Label");
                                file_system = columns[0].split ("=")[1];
                            }
                        // Find the partition corresponding to the UUID
                        } else {
                            if (columns[0].has_prefix ("UUID=")) {
                                if (GLib.FileUtils.test ("/dev/disk/by-uuid/", GLib.FileTest.IS_DIR)) {
                                    uuid = columns[0].split ("=")[1];
                                    if (GLib.FileUtils.test ("/dev/disk/by-uuid/" + uuid, GLib.FileTest.IS_SYMLINK)) {
                                        info("Disk with UUID [%s] exists in UUID dir", uuid);
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

                        if (is_real_disk (file_system, columns[2], columns[1])) {
                            debug("Partition identifier: [%s]", file_system);
                            var disk = new DiskEntry (file_system, columns[1], columns[2], columns[3], columns[4], columns[5]);
                            disk.uuid = uuid;
                            if (label != null) {
                                disk.name = label;
                            }

                            disks.append(disk);
                        } else {
                            warning("Partition [%s] is not 'real', do not add it", file_system);                            
                        }
                    }
                }
            }
        }

        //  loadSettings(); // to get the mountCommands
    }

    /**
     * reads the df-commands results
     */
    public void readDF () {
        // Avoid recreating disk entries multiple times
        if (readingDFStdErrOut) {
            info ("already reading df output, do not read a second time");
            return;
        }            

        string[] df = {"df", "-kT"};
        string[] spawn_env =
            {"LANG=en_US", "LC_ALL=en_US", "LC_MESSAGES=en_US", "LC_TYPE=en_US","LANGUAGE=en_US", "LC_ALL=POSIX"};
        string fstab_output;
        GLib.Process.spawn_sync ("/", df, spawn_env, SpawnFlags.SEARCH_PATH, null, out fstab_output);

        readingDFStdErrOut = true;

        DiskEntry disk;
        for (uint i = disks.get_n_items (); i --> 0; ) {
            disk = (DiskEntry) disks.get_item (i);
            disk.mounted = false; // set all disks unmounted
        }

        string[] lines = fstab_output.split ("\n");

        int line_idx = 0;
        for (;line_idx < lines.length; ++line_idx) {
            var line = lines[line_idx]._strip ();
            if (line.has_prefix ("Filesystem")) {
                ++line_idx;
                break;
            }
        }
        if (line_idx >= lines.length) {
            error("Error running df command... got [%s]", fstab_output);
        }

        warning ("check df non header lines to find their size");
        for (;line_idx < lines.length; ++line_idx) {
            var line = lines[line_idx]._strip ();
            if (line.length != 0) {
                if (!line.contains(Blank)) {// devicename was too long, the rest is on next line
                    var next_idx = line_idx + 1;
                    // append the next line
                    if (next_idx < lines.length) {
                        line += lines[next_idx]._strip ();
                    }
                };

                var words = string_to_array (line);
                if (words.length >= 7) {
                    var device_name = words[0];
                    var fs_type = words[1];
                    var kb_size = words[2];
                    var mount_point = words[6];

                    // Exclude virtual filesystems
                    if (is_real_disk_and_has_space (kb_size, device_name, fs_type, mount_point)) {
                        disk = null;
                        for (var i = 0; i < disks.n_items && disk == null; ++i) {
                            var current_disk = (DiskEntry) disks.get_item (i);
                            if (current_disk.file_system == device_name && current_disk.mount_point == mount_point) {
                                disk = current_disk;
                                debug ("found disk: %s", disk.file_system);
                            }
                        }

                        if (disk != null) {
                            disk.fs_type = fs_type;
                            disk.kb_size = uint64.parse (kb_size);
                            disk.kb_used = uint64.parse (words[3]);
                            disk.kb_avail = uint64.parse (words[4]);
                            //  disk.avail_percent = words[5]; // can be calculated
                            disk.mounted = true; // it is now mounted (df lists only mounted)

                        }
                    }
                } else {
                    error ("wrong number of values for line: %s", line);
                }
            }
        }

        readingDFStdErrOut = false;
        //  loadSettings(); // to get the mountCommands
    }

    // TODO add periodic refresh with "readDF ()"
    public void refresh () {
        info ("Remove and rescan disks");

        while (disks.n_items > 0) {
            disks.remove (0);
        }

        readFSTAB ();
        readDF ();
        on_items_changed ();
    }

    public void on_items_changed () {
        has_items = disks != null && disks.n_items > 0;
    }

    private void on_selected_disk_changed () {
        // TODO implement select disk change
    }

    /**
     * Split strings separated by tabs and (multiple) spaces to an array
     */
    private static string[] string_to_array (string str) {
        string clean_line = str.replace ("\t", " ");
        string prev_line = "";
        do {
            prev_line = clean_line;
            clean_line = clean_line.replace ("  ", Blank);
        } while (prev_line != clean_line);

        return clean_line.split (Blank);
    }

    /**
     * Check if filesystem is not empty and is real. See #is_real_disk ()
     */
    private static bool is_real_disk_and_has_space (string kb_size, string device_name, string fs_type, string mount_point) {
        debug ("kb_size: %s, device_name: %s, fs_type: %s, mount_point: %s", kb_size, device_name, fs_type, mount_point);
        return kb_size != "0" && device_name != "none"
            && fs_type != "swap" && fs_type != "sysfs" && fs_type != "rootfs" && fs_type != "tmpfs"
            && fs_type != "debugfs" && fs_type != "devtmpfs" && fs_type != "proctmpfs"
            && mount_point != "/dev/swap" && mount_point != "/dev/pts" && mount_point != "/dev/shm"
            && !mount_point.has_prefix ("/sys/") && !mount_point.has_prefix ("/proc/");
    }

    /**
     * Check if filesystem is named "none" or is swap, sysfs, rootfs, tmpfs (/dev/shm), debugfs, devtmpfs,
     *  /dev/pts or /proc/*
     */
    private static bool is_real_disk (string device_name, string fs_type, string mount_point) {
        return is_real_disk_and_has_space("", device_name, fs_type, mount_point);
    }
}
