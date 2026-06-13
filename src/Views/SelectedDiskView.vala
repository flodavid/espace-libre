/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2026 flodavid
 */

public class EspaceLibre.SelectedDiskView : Gtk.Box {
    private Gtk.Image folder_image;
    private Gtk.Button unmount_eject_button;

    construct {
        var volume_group = new Adw.PreferencesGroup () {
            title = _("Partition Details"),
            tooltip_text = _("Partition Name and Infos"),
        };

        var file_system_format = new Adw.ActionRow () {
            title = _("File System Format"),
            subtitle = _("Unknown FS"),
            subtitle_selectable = true,
        };
        //  Emphasize subtitle instead of title
        file_system_format.add_css_class ("property");

        var partition_label = new Adw.ActionRow () {
            title = _("Partition Label"),
            subtitle = _("Label"),
            subtitle_selectable = true,
        };
        //  Emphasize subtitle instead of title
        partition_label.add_css_class ("property");

        var partition_identifier = new Adw.ActionRow () {
            title = _("Partition ID"),
            subtitle = _("Partition"),
            subtitle_selectable = true,
        };
        //  Emphasize subtitle instead of title
        partition_identifier.add_css_class ("property");

        volume_group.add (file_system_format);
        volume_group.add (partition_label);
        volume_group.add (partition_identifier);

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

        var drive_group = new Adw.PreferencesGroup () {
            title = _("Drive Details"),
            tooltip_text = _("Drive Infos"),
        };

        var DeviceType = new Adw.ActionRow () {
            title = _("Device type"),
            subtitle = _("Device Type"),
            subtitle_selectable = true,
        };
        //  Emphasize subtitle instead of title
        DeviceType.add_css_class ("property");
        
        drive_group.add (DeviceType);

        append (volume_group);
        append (mount_info);
        append (unmount_eject_working_stack);
        append (drive_group);

        var disks_manager = DisksManager.get_default ();

        disks_manager.notify["current-disk"].connect (() => {
            debug ("selected disk changed");
            if (disks_manager.current_disk != null) {
                partition_label.subtitle = disks_manager.current_disk.label != null
                    ? disks_manager.current_disk.label
                    : "<i>None</i>";
                partition_identifier.subtitle = disks_manager.current_disk.file_system;
                file_system_format.subtitle = disks_manager.current_disk.fs_type;
                DeviceType.subtitle = disks_manager.current_disk.device_type.device_type_name ();
                mount_info.update_mount_point (disks_manager.current_disk.mount_point);
            } else {
                partition_identifier.subtitle = _("Not mounted");
            }
        });
    }
}
