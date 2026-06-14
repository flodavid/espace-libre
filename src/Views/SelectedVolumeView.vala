/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2026 flodavid
 */

public class EspaceLibre.SelectedVolumeView : Gtk.Box {
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

        var unmount_eject_working_stack = new Gtk.Stack () {
            margin_start = 6,
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };

        unmount_eject_working_stack.add_child (unmount_eject_button);
        unmount_eject_working_stack.add_child (working_spinner);

        orientation = Gtk.Orientation.VERTICAL;
        spacing = 12;

        var drive_group = new Adw.PreferencesGroup () {
            title = _("Drive Details"),
            tooltip_text = _("Drive Infos"),
        };

        var device_type = new Adw.ActionRow () {
            title = _("Device type"),
            subtitle = _("Device Type"),
            subtitle_selectable = true,
        };
        //  Emphasize subtitle instead of title
        device_type.add_css_class ("property");
        
        drive_group.add (device_type);

        append (volume_group);
        append (mount_info);
        append (unmount_eject_working_stack);
        append (drive_group);

        var volumes_manager = VolumesManager.get_default ();

        volumes_manager.notify["current-volume"].connect (() => {
            debug ("selected volume changed");
            working_spinner.stop ();
            unmount_eject_working_stack.visible_child = unmount_eject_button;
            unmount_eject_working_stack.visible = false;

            if (volumes_manager.current_volume != null) {
                unmount_eject_button.tooltip_text = volumes_manager.current_volume.can_eject
                    ? _("Eject Device") : _("Unmount Volume");

                if (volumes_manager.current_volume.can_eject || volumes_manager.current_volume.can_unmount) {
                    unmount_eject_working_stack.visible = true;
                }

                partition_label.subtitle = volumes_manager.current_volume.label != null
                    ? volumes_manager.current_volume.label
                    : "<i>None</i>";
                partition_identifier.subtitle = volumes_manager.current_volume.file_system;
                file_system_format.subtitle = volumes_manager.current_volume.fs_type;
                device_type.subtitle = volumes_manager.current_volume.device_type.device_type_name ();
                mount_info.update_mount_point (volumes_manager.current_volume.mount_point);
            } else {
                partition_identifier.subtitle = _("Not mounted");
            }
        });


        unmount_eject_button.clicked.connect (() => {
            working_spinner.start ();
            unmount_eject_working_stack.visible_child = working_spinner;
            
            volumes_manager.unmount_current.begin ((obj, res) => {
                working_spinner.stop ();
                unmount_eject_working_stack.visible_child = unmount_eject_button;
                unmount_eject_working_stack.visible = false;

                volumes_manager.unmount_current.end (res);
            });
        });
    }
}
