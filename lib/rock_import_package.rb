
require 'json'

# hackily reopen and extend the ImporterPackage class to store cmake args fo a colcon.pkg file
module Autobuild 
    class ImporterPackage

        #re-implement the original initialize of ImporterPackage + init @colcon_pkg
        def initialize(*args)
            @exclude = []
            @colcon_pkg = Hash.new
            super
        end
        
        # function to add a cmake arg
        def add_cmake_arg(value)
            if !@colcon_pkg.has_key?("cmake-args") then
                @colcon_pkg["cmake-args"] = Array.new
            end
            # add it to the stored list
            @colcon_pkg["cmake-args"].push(value)
        end

        # parse/append/write colcon.pkg file if cmake-args were eadded via add_cmake_arg()
        def write_colcon_pkg_file()
            # the cmake-args key is only present if add_cmake_arg was called
            if @colcon_pkg.has_key?("cmake-args") then
                output = Hash.new
                if File.exist?(srcdir + "/colcon.pkg") then
                    File.open(srcdir + "/colcon.pkg") do |file|
                        #load output with existing file to keep all values
                        output = JSON.load(file)
                    end
                end
                # merge new cmake-args to output
                # if !output.has_key?("cmake-args") then
                #     # add key
                #     output["cmake-args"] = Array.new
                # end
                # output["cmake-args"] |= @colcon_pkg["cmake-args"] 
                
                # overwrite cmake-args, as those which were added by call to pkg.add_cmake_arg() have to be removed from the file
                # (re-loaded) by parsing the file
                output["cmake-args"] = @colcon_pkg["cmake-args"] 

                File.write(self.srcdir + "/colcon.pkg", JSON.pretty_generate(output))
            end
        end

    end
end

def generate_package_xml(pkg, dependencyname)
    #puts "generate_package_xml" + pkg.srcdir + "/package.xml"
    if !File.exist?(pkg.srcdir + "/package.xml") then
        puts "  package.xml not present, generating for " + pkg.name
        content = \
        %{<?xml version="1.0"?>
<package format="2">
  <name>#{dependencyname}</name>
  <version>0.0.0</version>
  <description>auto generated file, see manifest.xml for information</description>
        }

        pkg.dependencies.each do |dep|
            content = content + "  <build_depend>#{dep.gsub("/","-")}</build_depend>\n"
        end

        content += %{
  <maintainer email="steffen.planthaber@dfki.de">Steffen Planthaber</maintainer>
  <license>Copyright DFKI</license>
  <export>
    <build_type>cmake</build_type>
  </export>
</package>
        }
        #puts content
        File.open(pkg.srcdir + "/package.xml", 'w') { |file| file.write(content) }
    end
end


def rock_import_package(name, type = :import_package, libname: name, workspace: Autoproj.workspace)
    ros_packagename = libname.gsub("/","-")

    send(type, name) do |pkg|
        pkg.post_import do 
            #if no package.xml exist, generate one including the dependencies
            generate_package_xml(pkg, ros_packagename)
            pkg.write_colcon_pkg_file()
        end
        yield(pkg) if block_given?
    end

    # add a metapackage to have both package definitions in autoproj:
    # with '/' and '-' (colcon cannot have / in package names), so aup
    # needs know the definition with '-' when calls from a plain ros2 package
    # with a manually written package.xml (use - version there to enable colcon to evaluate the dependency)
    metapackage ros_packagename, name
end



