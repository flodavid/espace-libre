project(
  'fr.flodavid.espaceLibre',
  'vala', 'c',
  version: '0.1.0',
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
granite_dep = dependency('granite-7', version: '>=7.6.0') # Granite.Bin
gtk_dep = dependency('gtk4')

dependencies = [
    adw_dep,
    granite_dep,
    gtk_dep
]

gnome.post_install(glib_compile_schemas: true)

subdir('data')
subdir('po')
subdir('src')
