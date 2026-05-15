/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2026 flodavid
 */

public class EspaceLibre.SelectedDiskView : Gtk.Box {
    private Gtk.Image folder_image;
    private Gtk.Button unmount_eject_button;

    construct {
        var disk_label = new Gtk.Label (_("Disk")) {
            tooltip_text = _("Partition Name"),
            ellipsize = Pango.EllipsizeMode.START
        };
        disk_label.add_css_class (Granite.STYLE_CLASS_H3_LABEL);

        var device_type = new Gtk.Label (_("Device type")) {
            tooltip_text = _("Device Type"),
            justify = Gtk.Justification.LEFT,
            halign = Gtk.Align.CENTER
        };
        device_type.add_css_class ("italic_text");

        var file_system_format = new Gtk.Label (_("Unknown FS")) {
            tooltip_text = _("File System Format"),
            justify = Gtk.Justification.LEFT,
            halign = Gtk.Align.START,
            ellipsize = Pango.EllipsizeMode.START
        };

        var partition_identifier = new Gtk.Label (_("Partition")) {
            tooltip_text = _("Partition ID"),
            justify = Gtk.Justification.LEFT,
            halign = Gtk.Align.START
        };

        var partition_info = new Gtk.Box (HORIZONTAL, 4);
        partition_info.append (file_system_format);
        partition_info.append (partition_identifier);

        var mount_info = new MountPointRow ();

        unmount_eject_button = new Gtk.Button.from_icon_name ("media-eject-symbolic");

        //  var devicerow_provider = new Gtk.CssProvider ();
        //  unmount_eject_button.get_style_context ().add_provider (devicerow_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        var working_spinner = new Gtk.Spinner ();

        var unmount_eject_revealer = new Gtk.Revealer () {
            child = unmount_eject_button,
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT,
            valign = Gtk.Align.CENTER,
            reveal_child = false
        };

        var unmount_eject_working_stack = new Gtk.Stack () {
            margin_start = 6,
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };

        unmount_eject_working_stack.add_child (unmount_eject_revealer);
        unmount_eject_working_stack.add_child (working_spinner);

        orientation = Gtk.Orientation.VERTICAL;
        spacing = 12;
        append (disk_label);
        append (device_type);
        append (partition_info);
        append (mount_info);
        append (unmount_eject_working_stack);

        var disks_manager = DisksManager.get_default ();

        disks_manager.notify["current-disk"].connect (() => {
            debug ("selected disk changed");
            if (disks_manager.current_disk != null) {
                partition_identifier.label = disks_manager.current_disk.file_system;
                disk_label.label = disks_manager.current_disk.name;
                file_system_format.label = disks_manager.current_disk.fs_type;
                device_type.label = disks_manager.current_disk.device_type.device_type_name ();
                mount_info.update_mount_point (disks_manager.current_disk.mount_point);
            } else {
                partition_identifier.label = _("Not mounted");
                disk_label.label = _("Disk");
            }
        });
    }
}
