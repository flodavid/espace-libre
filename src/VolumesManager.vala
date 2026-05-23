/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2026 flodavid
 */

public class EspaceLibre.VolumesManager : Object {
    public static unowned VolumesManager get_default () {
        return instance.once (() => { return new VolumesManager (); });
    }

    public VolumeEntry? current_volume { get; set; default = null; }
    public unowned GLib.List<VolumeEntry> volumes { get; private set; }
    
    public signal void invalids_found (int count);
    public signal void items_changed ();

    private static string BLANK = " ";
    private static GLib.Once<VolumesManager> instance;

    private bool reading_df_stderr_out;
    private VolumesManager () {}

    construct {
        reading_df_stderr_out = false;
        volumes = new GLib.List<VolumeEntry> ();

        //  volumes.items_changed.connect (on_items_changed);
    }

    //  public void show_volume (VolumeEntry volume) {
    //      print ("show_volume: %s\n", volume.get_name ());
    //      volumes.append (volume);
    //  }

    public bool has_items () {
        return volumes.length () > 0;
    }

    /**
     * tries to figure out the possibly mounted fs
     */
    public void add_volumes_from_FSTAB () {
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
                                    info ("Disk with label [%s] exists in Label dir", label);
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
                                        info ("Disk with UUID [%s] exists in UUID dir", uuid);
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
                            debug ("Partition identifier: [%s]", file_system);
                            var fs_volume = new FstabVolume (
                                file_system, columns[1], columns[2], columns[3], columns[4], columns[5]);
                            fs_volume.uuid = uuid;
                            if (label != null) {
                                fs_volume.label = label;
                            }

                            print ("add volume: %s\n", fs_volume.get_name ());
                            volumes.append (fs_volume);
                        } else {
                            warning ("Partition [%s] is not 'real', do not add it", file_system);
                        }
                    }
                }
            }
        }

        items_changed ();
    }

    /**
     * Get the non-system mounted volumes
     */
    public void add_volumes_from_volume_monitor () {
        var volume_infos = VolumeMonitor.get ().get_volumes ();
        if (volume_infos != null) {
            foreach (var volume_info in volume_infos) {
                warning ("adding %s", volume_info.get_name ());
                var device_type = partition_rotational_type (
                    volume_info.get_name (), volume_info.get_identifier ("unix-device").substring (5, 3));
                volumes.append(new GenericVolume(volume_info, device_type));
            }
        }

        var infos = VolumeMonitor.get ().get_mounts ();
        if (infos != null) {
            foreach (var info in infos) {
                warning ("drive %s", info.get_name ());

                var volume_info = info.get_volume ();
                if (volume_info != null) {
                    warning ("adding %s", volume_info.get_name ());
                    var device_type = partition_rotational_type (
                        volume_info.get_name (), volume_info.get_identifier ("unix-device").substring (5, 3));
                    volumes.append(new GenericVolume(volume_info, device_type));
                }
            }
        }

        items_changed ();
    }

    /**
     * Get the non-system mounted volumes
     */
    public void add_system_volumes () {
        var data_dirs = new Gee.ArrayList<string> ();
        data_dirs.add ("/");
        data_dirs.add ("/home");
        data_dirs.add ("/var");
        var small_dirs = new Gee.ArrayList<string> ();
        small_dirs.add ("/bin");
        small_dirs.add ("/etc");
   
        foreach (var dir in data_dirs) {
            get_dir_metadata (dir);
        }
    
        foreach (var dir in small_dirs) {
            get_dir_metadata (dir);
        }

        items_changed ();
    }
    
    private void get_dir_metadata (string dir_path) {
        print ("\ndata dir: %s\n", dir_path);
        var info = File.new_for_path(dir_path).query_filesystem_info ("filesystem::*");

        if (info != null) {
            if (info.has_attribute (FileAttribute.STANDARD_DISPLAY_NAME)) {
                string display_name = info.get_attribute_string (FileAttribute.STANDARD_DISPLAY_NAME);
                print ("display_name: %s\n", display_name);
            }
            if (info.has_attribute (FileAttribute.STANDARD_NAME)) {
                string name = info.get_attribute_string (FileAttribute.STANDARD_NAME);
                print ("name: %s\n", name);
            }
            if (info.has_attribute (FileAttribute.FILESYSTEM_SIZE)) {
                uint64 kb_size = info.get_attribute_uint64 (FileAttribute.FILESYSTEM_SIZE) / 1048576;
                print ("size: %lluMo\n", kb_size);
            }
            if (info.has_attribute (FileAttribute.FILESYSTEM_FREE)) {
                uint64 kb_avail = info.get_attribute_uint64 (FileAttribute.FILESYSTEM_FREE) / 1048576;
                print ("space available: %lluMo\n", kb_avail);
            }
            if (info.has_attribute (FileAttribute.FILESYSTEM_USED)) {
                uint64 fs_used = info.get_attribute_uint64 (FileAttribute.FILESYSTEM_USED) / 1048576;
                print ("fs_used: %lluMo\n", fs_used);
            }
            if (info.has_attribute (FileAttribute.FILESYSTEM_TYPE)) {
                string fs_type = info.get_attribute_string (FileAttribute.FILESYSTEM_TYPE);
                print ("fs_type: %s\n", fs_type);
            }
            if (info.has_attribute (FileAttribute.ID_FILE)) {
                string id_file = info.get_attribute_string (FileAttribute.ID_FILE);
                print ("id_file: %s\n", id_file);
            }
            if (info.has_attribute (FileAttribute.ID_FILESYSTEM)) {
                string id_filesystem = info.get_attribute_string (FileAttribute.ID_FILESYSTEM);
                print ("id_filesystem: %s\n", id_filesystem);
            }
            if (info.has_attribute (FileAttribute.MOUNTABLE_UNIX_DEVICE_FILE)) {
                string mountable = info.get_attribute_string (FileAttribute.MOUNTABLE_UNIX_DEVICE_FILE);
                print ("mountable: %s\n", mountable);
            }
            if (info.has_attribute (FileAttribute.STANDARD_TARGET_URI)) {
                string uri = info.get_attribute_string (FileAttribute.STANDARD_TARGET_URI);
                print ("uri: %s\n", uri);
            }
            if (info.has_attribute (FileAttribute.MOUNTABLE_UNIX_DEVICE)) {
                uint mountable = info.get_attribute_uint32 (FileAttribute.MOUNTABLE_UNIX_DEVICE);
                print ("mountable: %u", mountable);
            }
            if (info.has_attribute (FileAttribute.UNIX_DEVICE)) {
                uint device = info.get_attribute_uint32 (FileAttribute.UNIX_DEVICE);
                print ("device: %u", device);
            }
            if (info.has_attribute (FileAttribute.UNIX_UID)) {
                uint id = info.get_attribute_uint32 (FileAttribute.UNIX_UID);
                print ("id: %u", id);
            }
            if (info.has_attribute (FileAttribute.UNIX_GID)) {
                uint gid = info.get_attribute_uint32 (FileAttribute.UNIX_GID);
                print ("gid: %u", gid);
            }
            if (info.has_attribute (FileAttribute.UNIX_INODE)) {
                uint64 inode = info.get_attribute_uint64 (FileAttribute.UNIX_INODE);
                print ("inode: %llu\n", inode);
            }
        }
    }


    //  /**
    //   * Alternative to readDf using VolumeMonitor. Could also be an alternative to readFSTAB.
    //   * All functionalities are not supported as system partitions are not reported as volumes
    //   */
    public void read_volumes () {
        //  GLib.Environment.get_system_data_dirs. // TODO use it ?

        //  Volume volume;
        //  for (uint i = volumes.get_n_items (); i --> 0; ) {
        //      volume = (Volume) volumes.get_item (i);
        //      volume.mounted = true; // set all volumes as mounted
        //  }
        foreach (var entry in volumes) {
            var fs_volume = (FstabVolume) entry;
            if (fs_volume != null) {
                add_volume_info (fs_volume);
            }
        }
    }

    private void add_volume_info (FstabVolume fstab_entry) {
        var volume_infos = VolumeMonitor.@get ().get_volumes ();
        if (volume_infos != null) {
            Volume volume = null;
            GLib.FileInfo info = null;
            for (unowned List<Volume>? volume_elem = volume_infos.first ();
                    volume_elem != null && info == null;
                    volume_elem = volume_elem.next)
            {
                volume = volume_elem.data;

                print ("volume %s. ID: %s. Label: %s\n",
                    volume.get_name (), volume.get_identifier ("unix-device"), volume.get_identifier ("label"));

                if (fstab_entry.file_system == volume.get_identifier ("unix-device"))
                {
                    print ("found volume %s. ID: %s. Label: %s\n",
                        volume.get_name (), volume.get_identifier ("unix-device"), volume.get_identifier ("label"));

                    try {
                        if (volume.get_mount () != null) {
                            info = volume.get_mount ().get_root ().query_filesystem_info ("filesystem::*");
                        } else {
                            //  current_volume.mounted = false; // TODO fix or remove
                            debug ("%s is not mounted", volume.get_name ());
                            info = volume.get_activation_root ().query_filesystem_info ("filesystem::*");
                        }
                    } catch (GLib.Error error) {
                        if (!(error is IOError.CANCELLED)) {
                            warning ("Error querying filesystem info for '%s': %s", volume.get_mount ().get_root ().get_uri (), error.message);
                        }

                        info = null;
                    }
                }
            }


            // System volumes are not listed, but they are mounted
            if (info == null && fstab_entry.mounted == true) {
                debug ("no volume found for a mounted volume, it must be a system partition");
                volume = null;
                info = File.new_for_path(fstab_entry.mount_point).query_filesystem_info ("filesystem::*");
                fstab_entry.mounted = false;
                //  fstab_entry.is_system = true; // TODO différencier monté et partition systène
            }

            if (volume != null) {
                fstab_entry.device_type = partition_rotational_type (
                    volume.get_name (), volume.get_identifier ("unix-device").substring (5, 3));
            }

            // TODO rework using VolumeEntry methods
            if (info != null) {
                if (info.has_attribute (FileAttribute.FILESYSTEM_SIZE)) {
                    fstab_entry.kb_size = info.get_attribute_uint64 (FileAttribute.FILESYSTEM_SIZE) / 1024;
                }
                if (info.has_attribute (FileAttribute.FILESYSTEM_FREE)) {
                    fstab_entry.kb_avail = info.get_attribute_uint64 (FileAttribute.FILESYSTEM_FREE) / 1024;
                }
                if ((fstab_entry.fs_type == "auto" || fstab_entry.fs_type == "fuse")
                    && info.has_attribute (FileAttribute.FILESYSTEM_TYPE))
                {
                    fstab_entry.fs_type = info.get_attribute_string (FileAttribute.FILESYSTEM_TYPE);
                }
            }
        }
    }

    /**
     * reads the df-commands results
     */
    public void read_df () {
        // Avoid recreating disk entries multiple times
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

        FstabVolume fs_volume;
        foreach (var entry in volumes) {
            fs_volume = (FstabVolume) entry;
            if (fs_volume != null) {
                fs_volume.mounted = false; // set all volumes unmounted
            }
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
                    if (is_real_disk_and_has_space (kb_size, device_name, fs_type, mount_point)) {
                        fs_volume = null;
                        // TODO use iterator
                        for (var i = 0; i < volumes.length () && fs_volume == null; ++i) {
                            var current_volume = (FstabVolume) volumes.nth_data (i);
                            if (fs_volume == null) {
                                continue;
                            }

                            if (current_volume.file_system == device_name && current_volume.mount_point == mount_point) {
                                fs_volume = current_volume;

                                string disk_partition = fs_volume.file_system.split ("/")[2];
                                fs_volume.device_type = partition_rotational_type (disk_partition, disk_partition.substring (0, 3));
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

        volumes = new GLib.List<VolumeEntry> ();

        add_volumes_from_volume_monitor ();

        //  add_volumes_from_FSTAB ();
        //  read_df ();
        //  read_volumes ();
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
     * Check if filesystem is not empty and is real. See #is_real_disk ()
     */
    private static bool is_real_disk_and_has_space (
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
    private static bool is_real_disk (string device_name, string fs_type, string mount_point) {
        return is_real_disk_and_has_space ("", device_name, fs_type, mount_point);
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
    private DeviceType partition_rotational_type (string disk_partition_name, string disk_partition_path) {
        if (disk_partition_path == "nvm") {
            debug ("disk [%s] is on NVMe Drive", disk_partition_name);
            return NVME;
        } else {
            int device_rotational = get_rotational (disk_partition_path);

            if (device_rotational == 1) {
                debug ("disk [%s] is on HDD", disk_partition_name);
                return HDD;
            } else {
                if (device_rotational == 0) {
                    debug ("disk [%s] is on SSD", disk_partition_name);
                    return SSD;
                } else {
                    warning ("disk [%s] rotational type is unknown", disk_partition_name);
                    return UNKNOWN;
                }
            }
        }
    }
}
