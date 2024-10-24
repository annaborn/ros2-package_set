
require_relative "./lib/colcon_package.rb"
require_relative "./lib/rock_import_package.rb"

os_names, os_versions = Autoproj.workspace.operating_system
if os_names.include?('ubuntu')
    if os_versions.include?('focal')
        Autoproj.message ("Load ros2 osdeps with the suffix 'focal'")
        Autoproj.workspace.osdep_suffixes << 'focal'
        Autoproj.message Autoproj.workspace.osdep_suffixes
    elsif os_versions.include?('jammy')
        Autoproj.message ("Load ros2 osdeps with the suffix 'jammy'")
        Autoproj.workspace.osdep_suffixes << 'jammy'
    elsif os_versions.include?('noble')
        Autoproj.message ("Load ros2 osdeps with the suffix 'noble'")
        Autoproj.workspace.osdep_suffixes << 'noble'
    else
        Autoproj.error("Unsupported ubuntu version #{is_versions}")
    end
else
    Autoproj.error("Unsupported os version: #{os_names}")
end

ros_setup_bash = File.join(Autoproj.root_dir, '../install/setup.bash')
if File.file?(ros_setup_bash)
    Autoproj.env_source_file ros_setup_bash
end

