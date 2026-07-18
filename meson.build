project(
  'fr.flodavid.espaceLibre',
  'vala', 'c',
  version: '1.0.0',
  meson_version: '>=0.58.0'
)

gnome = import('gnome')
i18n = import('i18n')

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')

config_data = configuration_data()
config_data.set_quoted('LOCALEDIR', join_paths(get_option('prefix'), get_option('localedir')))
config_data.set_quoted('GETTEXT_PACKAGE', meson.project_name())
config_file = configure_file(
    input: 'src/Config.vala.in',
    output: '@BASENAME@',
    configuration: config_data
)

adw_dep = dependency('libadwaita-1', version: '>=1.4.0')
gtk_dep = dependency('gtk4')
# Granite.Bin and Granite.MessageDialog
granite_dep = dependency('granite-7', version: '>=7.7.0')
# GRANITE < 7.7
#granite_dep = dependency('granite-7', version: '>=7.6.0')
#add_project_arguments('--define=GRANITE_7_6_OR_LOWER', language: 'vala')

# For Flatpak only:
add_project_arguments('--define=IS_FLATPAK', language: 'vala')

dependencies = [
    adw_dep,
    granite_dep,
    gtk_dep,
    meson.get_compiler('vala').find_library('posix'),
]

gnome.post_install(glib_compile_schemas: true)

subdir('data')
subdir('po')
subdir('src')
