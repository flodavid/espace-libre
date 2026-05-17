/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2026 flodavid
 */

public class EspaceLibre.FstabVolume : GLib.Object, GLib.Volume, VolumeEntry {

    public string file_system { get; construct; }
    public string mount_point { get; set; }
    private string m_fs_type { get; set; }
    public string fs_type {
        get {
            return m_fs_type;
        }
        set {
            m_fs_type = value;
        }
    }
    public string mount_options { get; construct; }
    public string dump { get; construct; }
    public string pass { get; construct; }
    public string ? label;
    public string uuid;
    public bool mounted { get; set; }
    public DeviceType device_type { get; set; }
    private uint64 m_kb_size { get; set; default = 0; }
    public uint64 kb_size {
        set {
            m_kb_size = value;
        }
    }
    private uint64 m_kb_used { get; set; default = 0; }
    public uint64 kb_used {
        set {
            m_kb_used = value;
        }
    }
    private uint64 m_kb_avail { get; set; default = 0; }
    public uint64 kb_avail {
        set {
            m_kb_avail = value;
        }
    }

    // TODO initiate drive and mount
    public Drive? drive;
    public Mount? v_mount { get; set construct; default = null; }

    public FstabVolume (string file_system, string mount_point, string format_type, string mount_options,
        string dump, string pass) {
        Object (file_system : file_system, mount_point : mount_point, fs_type: format_type,
                mount_options: mount_options, dump: dump, pass: pass);
    }

    construct {
        drive = null;
        mounted = false;
        device_type = UNKNOWN;
    }


    public bool can_mount () {
        return !mounted && v_mount != null;
    }

    public bool can_eject () {
        return mounted && v_mount != null && v_mount.can_eject ();
    }

    public async bool eject (MountUnmountFlags flags, Cancellable? cancellable = null) {
        return false;
    }

    public async bool eject_with_operation (MountUnmountFlags flags, MountOperation? mount_operation,
                                            Cancellable? cancellable = null) {
        return false;
    }

    public string[] enumerate_identifiers () {
        // TODO add identifiers
        var identifiers = new string[1];
        identifiers[0] = "unix-device";
        return identifiers;
    }

    public File ? get_activation_root () {
        // TODO return something other than null ?
        return null;
    }

    public Drive ? get_drive () {
        return drive;
    }

    public Icon get_icon () {
        GLib.Icon icon = null;

        switch (device_type) {
        case HDD :
            icon = GLib.Icon.new_for_string ("drive-harddisk");
            break;
        case USB_DRIVE :
            icon = GLib.Icon.new_for_string ("drive-removable-media-usb");
            break;
        case OPTICAL :
            icon = GLib.Icon.new_for_string ("media-optical");
            break;
        case NVME :
        case SSD :
            default :
            icon = GLib.Icon.new_for_string ("drive-harddisk-solidstate");
            break;
        }

        return icon;
    }

    public string ? get_identifier (string kind) {
        // TODO support more identifiers
        if (kind == "unix-device") {
            return file_system;
        }
        return null;
    }

    public Mount ? get_mount () {
        return v_mount;
    }

    public string get_name () {
        return label;
    }

    public unowned string ? get_sort_key () {
        return file_system;
    }

    public Icon get_symbolic_icon () {
        GLib.Icon icon = null;

        switch (device_type) {
        case HDD :
            icon = GLib.Icon.new_for_string ("drive-harddisk-symbolic");
            break;
        case USB_DRIVE :
            icon = GLib.Icon.new_for_string ("drive-removable-media-usb-symbolic");
            break;
        case OPTICAL :
            icon = GLib.Icon.new_for_string ("media-optical-symbolic");
            break;
        case NVME :
        case SSD :
            default :
            icon = GLib.Icon.new_for_string ("drive-harddisk-solidstate-symbolic");
            break;
        }

        return icon;
    }

    public string? get_uuid () {
        return uuid;
    }

    public async bool mount (MountMountFlags flags, MountOperation? mount_operation, Cancellable? cancellable = null) {
        return false;
    }

    public bool should_automount () {
        return true;
    }

    public string get_fs_type () {
        return fs_type;
    }

    public virtual uint64 get_kb_size () {
        return m_kb_size;
    }

    public virtual uint64 get_kb_used () {
        return m_kb_used;
    }

    public virtual  uint64 get_kb_avail () {
        return m_kb_avail;
    }

    public string get_device_type_name () {
        return device_type.device_type_name ();
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
