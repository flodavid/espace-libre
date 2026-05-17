/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2026 flodavid
 */

public class EspaceLibre.GenericVolume : GLib.Object, GLib.Volume, VolumeEntry {
    private GLib.Volume volume;
    private DeviceType device_type;

    public GenericVolume (GLib.Volume volume, DeviceType device_type) {
        this.volume = volume;
        this.device_type = device_type;
    }

    public string get_fs_type () {
        var info = get_file_info ();
        if (info != null) {
            if (info.has_attribute (FileAttribute.FILESYSTEM_TYPE)) {
                return info.get_attribute_string (FileAttribute.FILESYSTEM_TYPE);
            }
        }
        return "";
    }

    public uint64 get_kb_size () {
        var info = get_file_info ();
        if (info != null) {
            if (info.has_attribute (FileAttribute.FILESYSTEM_SIZE)) {
                return info.get_attribute_uint64 (FileAttribute.FILESYSTEM_SIZE) / 1024;
            }
        }
        return 0;
    }

    public uint64 get_kb_used () {
        var info = get_file_info ();
        if (info != null) {
            if (info.has_attribute (FileAttribute.FILESYSTEM_USED)) {
                return info.get_attribute_uint64 (FileAttribute.FILESYSTEM_USED) / 1024;
            } else {
                return get_kb_size () - get_kb_avail ();
            }
        }
        return 0;
    }

    public uint64 get_kb_avail () {
        var info = get_file_info ();
        if (info != null) {
            if (info.has_attribute (FileAttribute.FILESYSTEM_FREE)) {
                return info.get_attribute_uint64 (FileAttribute.FILESYSTEM_FREE) / 1024;
            }
        }
        return 0;
    }

    public bool can_mount () {
        return volume.can_mount ();
    }

    public bool can_eject () {
        return volume.can_eject ();
    }

    public async bool eject (MountUnmountFlags flags, Cancellable? cancellable = null) {
        bool result = false;
        volume.eject.begin (flags, cancellable, (obj, res) => {
            result = eject.end (res);
        });
        yield;
        return result;
    }

    public async bool eject_with_operation (MountUnmountFlags flags, MountOperation? mount_operation,
                                            Cancellable? cancellable = null) {
        bool result = false;
        volume.eject_with_operation.begin (flags, mount_operation, cancellable, (obj, res) => {
            result = true;
            eject_with_operation.end (res);
        });
        yield;
        return result;
    }

    public string[] enumerate_identifiers () {
        return volume.enumerate_identifiers ();
    }

    public File ? get_activation_root () {
        return volume.get_activation_root ();
    }

    public Drive ? get_drive () {
        return volume.get_drive ();
    }

    public Icon get_icon () {
        return volume.get_icon ();
    }

    public string ? get_identifier (string kind) {
        return volume.get_identifier (kind);
    }

    public Mount ? get_mount () {
        return volume.get_mount ();
    }

    public string get_name () {
        return volume.get_name ();
    }

    public unowned string ? get_sort_key () {
        return volume.get_sort_key ();
    }

    public Icon get_symbolic_icon () {
        return volume.get_symbolic_icon ();
    }

    public string? get_uuid () {
        return volume.get_uuid ();
    }

    public async bool mount (MountMountFlags flags, MountOperation? mount_operation, Cancellable? cancellable = null) {
        bool result = false;
        volume.mount.begin (flags, mount_operation, cancellable, (obj, res) => {
            result = mount.end (res);
        });
        yield;
        return result;
    }

    public bool should_automount () {
        return volume.should_automount ();
    }

    public string get_device_type_name () {
        return device_type.device_type_name ();
    }


    private GLib.FileInfo? get_file_info () {
        if (volume.get_mount () != null) {
            return volume.get_mount ().get_root ().query_filesystem_info ("filesystem::*");
        } else {
            return volume.get_activation_root ().query_filesystem_info ("filesystem::*");
        }
    }
}
