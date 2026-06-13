/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2026 flodavid
 */

public class EspaceLibre.VolumesManager : Object {
    public static unowned VolumesManager get_default () {
        return instance.once (() => { return new VolumesManager (); });
    }

    public VolumeEntry? current_volume { get; set; default = null; }
    public ListStore volumes { get; private set; }
    
    public signal void invalids_found (int count);

    private static string BLANK = " ";
    private static GLib.Once<VolumesManager> instance;

    private bool reading_df_stderr_out;
    private VolumesManager () {}

    construct {
        reading_df_stderr_out = false;
        volumes = new ListStore (typeof (VolumeEntry));

        //  volumes.items_changed.connect (on_items_changed);
    }

    public bool has_items () {
        return volumes.get_n_items () > 0;
    }

    /**
     * tries to figure out the possibly mounted fs
     */
    public void add_volumes_from_fstab () {
        string fstab_content;
        
        try {
            FileUtils.get_contents ("/run/host/etc/fstab", out fstab_content);
        } catch (FileError err) {
            fstab_content = null;
        }
        if (fstab_content == null || fstab_content == "") {
            FileUtils.get_contents ("/etc/fstab", out fstab_content);
        }

        if (fstab_content != null && fstab_content != "") {
            string[] lines = fstab_content.split ("\n");
            foreach (string line in lines) {
                line = line.strip ();
                // Treat lines not empty or commented out by '#'
                if (line.length > 0 && line.get_char (0) != '#') {
                    info ("GOT: [%s]", line);

                    var columns = string_to_array (line);

                    // Remove LABEL= and UUID=
                    if (columns[0] != null && columns[1] != null && columns[2] != null && columns[3] != null
                        && columns[4] != null && columns[5] != null
                    ) {
                        string file_system = columns[0];
                        string label = null;
                        string uuid = "";

                        if (columns[0].has_prefix ("LABEL=")) {
                            if (GLib.FileUtils.test ("/dev/disk/by-label/", GLib.FileTest.IS_DIR)) {
                                label = columns[0].split ("=")[1];
                                if (GLib.FileUtils.test ("/dev/disk/by-label/" + label, GLib.FileTest.IS_SYMLINK)) {
                                    info ("Volume with label [%s] exists in Label dir", label);
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
                                        info ("Volume with UUID [%s] exists in UUID dir", uuid);
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

                        if (is_real_volume (file_system, columns[2], columns[1])) {
                            debug ("Partition identifier: [%s]", file_system);
                            var fs_volume = new VolumeEntry (
                                file_system, columns[1], columns[2], columns[3], columns[4], columns[5]);
                            fs_volume.uuid = uuid;
                            if (label != null) {
                                fs_volume.label = label;
                            }

                            print ("add volume: %s\n", fs_volume.file_system);
                            volumes.append (fs_volume);
                        } else {
                            warning ("Partition [%s] is not 'real', do not add it", file_system);
                        }
                    }
                }
            }
        }
    }

    /**
     * reads the df-commands results
     */
    public void read_df () {
        // Avoid recreating volume entries multiple times
        if (reading_df_stderr_out) {
            info ("already reading df output, do not read a second time");
            return;
        }

        string[] df = {"df", "-kT"};
        string[] spawn_env = {
            "LANG=en_US", "LC_ALL=en_US", "LC_MESSAGES=en_US", "LC_TYPE=en_US","LANGUAGE=en_US", "LC_ALL=POSIX"
        };
        string df_output;
        GLib.Process.spawn_sync ("/", df, spawn_env, SpawnFlags.SEARCH_PATH, null, out df_output);

        reading_df_stderr_out = true;

        VolumeEntry fs_volume;
        for (uint i = volumes.get_n_items (); i --> 0; ) {
            fs_volume = (VolumeEntry) volumes.get_item (i);
            fs_volume.mounted = false; // set all volumes unmounted
        }

        string[] lines = df_output.split ("\n");

        int line_idx = 0;
        for (;line_idx < lines.length; ++line_idx) {
            var line = lines[line_idx]._strip ();
            if (line.has_prefix ("Filesystem")) {
                ++line_idx;
                break;
            }
        }
        if (line_idx >= lines.length) {
            error ("Error running df command… got [%s]", df_output);
        }

        debug ("reading df non header lines to find their size");
        for (;line_idx < lines.length; ++line_idx) {
            var line = lines[line_idx]._strip ();
            if (line.length != 0) {
                if (!line.contains (BLANK)) {// devicename was too long, the rest is on next line
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
                    if (is_real_volume_and_has_space (kb_size, device_name, fs_type, mount_point)) {
                        fs_volume = null;
                        // TODO use iterator
                        for (var i = 0; i < volumes.n_items && fs_volume == null; ++i) {
                            var current_volume = (VolumeEntry) volumes.get_item (i);
                            if (current_volume == null) {
                                continue;
                            }

                            if (current_volume.file_system == device_name && current_volume.mount_point == mount_point) {
                                fs_volume = current_volume;

                                string partition = fs_volume.file_system.split ("/")[2];
                                fs_volume.device_type = partition_rotational_type (partition, partition.substring (0, 3));
                            }
                        }

                        if (fs_volume != null) {
                            fs_volume.fs_type = fs_type;
                            fs_volume.kb_size = uint64.parse (kb_size);
                            fs_volume.kb_used = uint64.parse (words[3]);
                            fs_volume.kb_avail = uint64.parse (words[4]);
                            //  disk.avail_percent = words[5]; // can be calculated
                            fs_volume.mounted = true; // it is now mounted (df lists only mounted)
                        }
                    }
                } else {
                    error ("wrong number of values for line: %s", line);
                }
            }
        }

        reading_df_stderr_out = false;
        //  loadSettings(); // to get the mountCommands
    }

    // TODO add periodic refresh with "read_df ()"
    public void refresh () {
        info ("Remove and rescan volumes");

        volumes = new ListStore (typeof (VolumeEntry));

        add_volumes_from_fstab ();
        //  add_volumes_from_volume_monitor ();

        read_df ();

        on_items_changed ();
    }

    public void on_items_changed () {
        //  bool before = has_items;

        //  if (has_items) {
        //      if (!before) {
        //          warning("had no items, but now has some");
        //          current_disk = (DiskEntry) volumes.get_item (0);
        //      } else {
        //          warning("still some items");
        //      }
        //  } else {
        //      if (before) {
        //          warning("no more items");
        //          current_disk = null;
        //      } else {
        //          warning("still no items");
        //      }
        //  }
    }

    /**
     * Split strings separated by tabs and (multiple) spaces to an array
     */
    private static string[] string_to_array (string str) {
        string clean_line = str.replace ("\t", " ");
        string prev_line = "";
        do {
            prev_line = clean_line;
            clean_line = clean_line.replace ("  ", BLANK);
        } while (prev_line != clean_line);

        return clean_line.split (BLANK);
    }

    /**
     * Check if filesystem is not empty and is real. See #is_real_volume ()
     */
    private static bool is_real_volume_and_has_space (
        string kb_size, string device_name, string fs_type, string mount_point
    ) {
        debug ("kb_size: %s, device_name: %s, fs_type: %s, mount_point: %s",
            kb_size, device_name, fs_type, mount_point);
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
    private static bool is_real_volume (string device_name, string fs_type, string mount_point) {
        return is_real_volume_and_has_space ("", device_name, fs_type, mount_point);
    }

    /**
     * reads the cat-command result for the given device name
     */
    private int get_rotational (string device_name) {
        debug ("get_rotational of %s", device_name);

        string[] cat = {"cat", "/sys/block/" + device_name + "/queue/rotational"};
        string[] spawn_env = { };
        string cat_output;
        string cat_error;
        GLib.Process.spawn_sync ("/", cat, spawn_env, SpawnFlags.SEARCH_PATH, null, out cat_output, out cat_error);
        cat_output = cat_output.strip ();

        if (cat_output == "0") {
            debug ("%s disk is NOT rotational", device_name);
            return 0;
        } else if (cat_output == "1") {
            debug ("%s disk is rotational", device_name);
            return 1;
        } else {
            warning ("Failed to check if the disk device is an HDD:\n\t%s\n%s", cat_output, cat_error);
            return -1;
        }
    }

    /**
     * get the type of drive, rotational disk, (NVMe) solid state drive.
     */
    private DeviceType partition_rotational_type (string partition_name, string partition_path) {
        if (partition_path == "nvm") {
            debug ("volume [%s] is on NVMe Drive", partition_name);
            return NVME;
        } else {
            int device_rotational = get_rotational (partition_path);

            if (device_rotational == 1) {
                debug ("volume [%s] is on HDD", partition_name);
                return HDD;
            } else {
                if (device_rotational == 0) {
                    debug ("volume [%s] is on SSD", partition_name);
                    return SSD;
                } else {
                    warning ("volume [%s] drive rotational type is unknown", partition_name);
                    return UNKNOWN;
                }
            }
        }
    }
}
