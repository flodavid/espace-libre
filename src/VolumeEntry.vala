/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2026 flodavid
 */

public interface EspaceLibre.VolumeEntry : GLib.Object, GLib.Volume {
    
    public abstract string get_fs_type ();

    public abstract uint64 get_kb_size ();

    public abstract uint64 get_kb_used ();

    public abstract uint64 get_kb_avail ();
    
    public abstract string get_device_type_name ();
}

public enum DeviceType {
    UNKNOWN, HDD, SSD, NVME, USB_DRIVE, OPTICAL;

    public string device_type_name () {
        switch (this) {
        case HDD:
            return _("Hard Drive Disk");
        case USB_DRIVE:
            return _("USB Drive");
        case OPTICAL:
            return _("Optical Disc");
        case NVME:
            return _("NVMe Solid State Drive");
        case SSD:
            return _("Solid State Drive");
        default:
            return _("Unknown type");
        }
    }
}
