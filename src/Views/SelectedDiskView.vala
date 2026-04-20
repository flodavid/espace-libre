/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2026 flodavid
 */

public class EspaceLibre.SelectedDiskView : Gtk.Box {
    construct {
        var disk_label = new Gtk.Label (_("Disk")) {
            ellipsize = Pango.EllipsizeMode.START
        };
        disk_label.add_css_class (Granite.STYLE_CLASS_H3_LABEL);

        var partition_name = new Gtk.Label (_("Partition")) {
            justify = Gtk.Justification.LEFT,
            halign = Gtk.Align.START
        };

        var mount_point = new Gtk.Label (_("Not mounted")) {
            justify = Gtk.Justification.LEFT,
            halign = Gtk.Align.START,
            ellipsize = Pango.EllipsizeMode.START
        };

        var file_system_format = new Gtk.Label (_("Unknown FS")) {
            justify = Gtk.Justification.LEFT,
            halign = Gtk.Align.START,
            ellipsize = Pango.EllipsizeMode.START
        };

        var device_type = new Gtk.Label (_("Device type")) {
            justify = Gtk.Justification.LEFT,
            halign = Gtk.Align.START
        };

        orientation = Gtk.Orientation.VERTICAL;
        spacing = 12;
        append (disk_label);
        append (partition_name);
        append (mount_point);
        append (file_system_format);
        append (device_type);

        var disks_manager = DisksManager.get_default ();

        disks_manager.notify["current-disk"].connect (() => {
            debug ("selected disk changed");
            if (disks_manager.current_disk != null) {
                if (disks_manager.current_disk.file_system != disks_manager.current_disk.name) {
                    partition_name.label = disks_manager.current_disk.file_system;
                } else {
                    partition_name.label = "";
                }
                disk_label.label = disks_manager.current_disk.name;
                mount_point.label = disks_manager.current_disk.mount_point;
                file_system_format.label = _("Format: ") + disks_manager.current_disk.fs_type;
                device_type.label = disks_manager.current_disk.device_type.device_type_name ();
            } else {
                partition_name.label = _("Not mounted");
                disk_label.label = _("Disk");
            }
        });
    }
}
