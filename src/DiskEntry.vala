/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2026 flodavid
 */

public class EspaceLibre.DiskEntry : Object {

    public string file_system { get; construct; }
    public string mount_point { get; set; }
    public string fs_type { get; set; }
    public string mount_options { get; construct; }
    public string dump { get; construct; }
    public string pass { get; construct; }
    public string name { get; set; }
    public string uuid { get; set; }
    public bool mounted { get; set; }
    public DEVICE_TYPE device_type { get; set; }
    public uint64 kb_size { get; set; default = 0; }
    public uint64 kb_used { get; set; default = 0; }
    public uint64 kb_avail { get; set; default = 0; }

    public DiskEntry (string file_system, string mount_point, string format_type, string mount_options,
        string dump, string pass)
    {
        Object (file_system: file_system, mount_point: mount_point, fs_type: format_type,
            mount_options: mount_options, dump: dump, pass: pass);
    }

    construct {
        name = file_system;
        mounted = false;
        device_type = UNKNOWN;
    }

    public Gdk.Paintable get_texture () {
        var display = Gdk.Display.get_default ();
        var icon_theme = Gtk.IconTheme.get_for_display (display);
        Gtk.IconPaintable icon_paint = null;

        switch (device_type) {
        case HDD:
            icon_paint = icon_theme.lookup_icon ("drive-harddisk", null, 64, 1, 0, 0);
            break;
        case USB_DRIVE:
            icon_paint = icon_theme.lookup_icon ("drive-removable-media-usb", null, 64, 1, 0, 0);
            break;
        case OPTICAL:
            icon_paint = icon_theme.lookup_icon ("media-optical", null, 64, 1, 0, 0);
            break;
        case NVME:
        case SSD:
        default:
            icon_paint = icon_theme.lookup_icon ("drive-harddisk-solidstate", null, 64, 1, 0, 0);
            break;
        }

        return icon_paint;
    }
}

public enum DEVICE_TYPE {
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
