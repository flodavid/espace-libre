/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2026 flodavid
 */

public class EspaceLibre.Application : Gtk.Application {
    public const string ACTION_PREFIX = "app.";
    public const string ACTION_REFRESH = "action-refresh";
    public const string ACTION_QUIT = "action-quit";

    private const ActionEntry[] ACTION_ENTRIES = {
        { ACTION_REFRESH, action_refresh },
        { ACTION_QUIT, quit }
    };

    private DisksManager? playback_manager = null;

    public Application () {
        Object (
            application_id: "fr.flodavid.espaceLibre",
            flags: ApplicationFlags.HANDLES_OPEN
        );
    }

    construct {
        GLib.Intl.setlocale (LocaleCategory.ALL, "");
        GLib.Intl.bindtextdomain (Constants.GETTEXT_PACKAGE, Constants.LOCALEDIR);
        GLib.Intl.bind_textdomain_codeset (Constants.GETTEXT_PACKAGE, "UTF-8");
        GLib.Intl.textdomain (Constants.GETTEXT_PACKAGE);
    }

    protected override void startup () {
        base.startup ();

        Granite.init ();

        playback_manager = DisksManager.get_default ();

        add_action_entries (ACTION_ENTRIES, this);

        set_accels_for_action (ACTION_PREFIX + ACTION_REFRESH, {"<Ctrl>R"});
        set_accels_for_action (ACTION_PREFIX + ACTION_QUIT, {"<Ctrl>Q"});

        var granite_settings = Granite.Settings.get_default ();
        var gtk_settings = Gtk.Settings.get_default ();

        gtk_settings.gtk_icon_theme_name = "elementary";

        gtk_settings.gtk_application_prefer_dark_theme = (
            granite_settings.prefers_color_scheme == DARK
        );

        granite_settings.notify["prefers-color-scheme"].connect (() => {
            gtk_settings.gtk_application_prefer_dark_theme = (
                granite_settings.prefers_color_scheme == DARK
            );
        });
    }

    protected override void activate () {
        if (active_window != null) {
            active_window.present ();
            return;
        }

        var main_window = new MainWindow () {
            title = _("Espace Libre")
        };
        main_window.present ();

        add_window (main_window);

        /*
        * This is very finicky. Bind size after present else set_titlebar gives us bad sizes
        * Set maximize after height/width else window is min size on unmaximize
        * Bind maximize as SET else get get bad sizes
        */
        var settings = new Settings ("fr.flodavid.espaceLibre");
        settings.bind ("window-height", main_window, "default-height", SettingsBindFlags.DEFAULT);
        settings.bind ("window-width", main_window, "default-width", SettingsBindFlags.DEFAULT);

        if (settings.get_boolean ("window-maximized")) {
            main_window.maximize ();
        }

        settings.bind ("window-maximized", main_window, "maximized", SettingsBindFlags.SET);
    }

    public static int main (string[] args) {
        return new EspaceLibre.Application ().run (args);
    }

    private void action_refresh () {
        ((MainWindow)active_window).start_refresh ();
    }
}
