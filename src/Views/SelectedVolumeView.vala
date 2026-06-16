/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2026 flodavid
 */

public class EspaceLibre.SelectedVolumeView : Gtk.Box {
    private unowned VolumesManager volumes_manager;
    private Gtk.Image folder_image;
    private Gtk.Button unmount_eject_button;
    private Gtk.Button mount_button;

    construct {
        orientation = Gtk.Orientation.VERTICAL;
        spacing = 12;

        volumes_manager = VolumesManager.get_default ();

        /* Volume information */
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

        /* Mount/unmount button depending on the volume status */
        unmount_eject_button = new Gtk.Button.from_icon_name ("media-eject-symbolic");
        mount_button = new Gtk.Button.from_icon_name ("media-playback-start-symbolic");
        mount_button.tooltip_text = _("Mount volume/device");
        var working_spinner = new Gtk.Spinner () {
            height_request = 28
        };

        var mount_eject_working_stack = new Gtk.Stack () {
            margin_start = 6,
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };

        mount_eject_working_stack.add_child (unmount_eject_button);
        mount_eject_working_stack.add_child (mount_button);
        mount_eject_working_stack.add_child (working_spinner);


        /* Drive information */
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

        /* General layout and signals */
        append (volume_group);
        append (mount_info);
        append (mount_eject_working_stack);
        append (drive_group);

        var volumes_manager = VolumesManager.get_default ();

        volumes_manager.notify["current-volume"].connect (() => {
            update_current_volume (working_spinner, mount_eject_working_stack, partition_label, partition_identifier,
                file_system_format, device_type, mount_info);
        });

        unmount_eject_button.clicked.connect (() => {
            unmount_eject_current_volume (working_spinner, mount_eject_working_stack);
        });

        mount_button.clicked.connect (() => {
            mount_current_volume (working_spinner, mount_eject_working_stack);
        });
    }

    private void update_current_volume (
        Gtk.Spinner working_spinner, Gtk.Stack mount_eject_working_stack, Adw.ActionRow partition_label,
        Adw.ActionRow partition_identifier, Adw.ActionRow file_system_format, Adw.ActionRow device_type,
        MountPointRow mount_info
    ) {
        debug ("selected volume changed");

        if (working_spinner.get_spinning ()) {
            working_spinner.stop ();
        }
        mount_eject_working_stack.visible = false;

        if (volumes_manager.current_volume != null) {
            unmount_eject_button.tooltip_text = volumes_manager.current_volume.can_eject
                ? _("Eject Device") : _("Unmount Volume");

            if (!volumes_manager.current_volume.is_system ()
                && (!volumes_manager.current_volume.mounted
                    || volumes_manager.current_volume.can_eject
                    || volumes_manager.current_volume.can_unmount)) {
                mount_eject_working_stack.visible = true;
            } else {
                debug ("%s cannot be mounted/ejected\n", volumes_manager.current_volume.file_system);
            }

            if (volumes_manager.current_volume.mounted) {
                mount_eject_working_stack.visible_child = unmount_eject_button;
            } else {
                if (volumes_manager.current_volume.glib_volume.can_mount ()) {
                    mount_eject_working_stack.visible_child = mount_button;
                } else {
                    mount_eject_working_stack.visible = false;
                    debug ("%s CANNOT be mounted in the end", volumes_manager.current_volume.file_system);      
                }
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
    }

    private void unmount_eject_current_volume (Gtk.Spinner working_spinner, Gtk.Stack mount_eject_working_stack) {
        working_spinner.start ();
        mount_eject_working_stack.visible_child = working_spinner;

        volumes_manager.unmount_current.begin ((obj, res) => {
            bool success = volumes_manager.unmount_current.end (res);

            working_spinner.stop ();
            if (success) {
                mount_eject_working_stack.visible_child = mount_button;
            } else {
                mount_eject_working_stack.visible_child = unmount_eject_button;
            }
        });
    }

    private void mount_current_volume (
        Gtk.Spinner working_spinner, Gtk.Stack mount_eject_working_stack
    ) {
        working_spinner.start ();
        mount_eject_working_stack.visible_child = working_spinner;
        
        volumes_manager.mount_current.begin ((obj, res) => {
            bool success = volumes_manager.mount_current.end (res);

            working_spinner.stop ();
            volumes_manager.current_volume.mounted = success;
            if (success) {
                mount_eject_working_stack.visible_child = unmount_eject_button;
                volumes_manager.refresh ();
            } else {
                mount_eject_working_stack.visible_child = mount_button;
            }
        });
    }
}
