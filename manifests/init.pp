# Class: oracle_java
#
# Installs Oracle JDK or JRE 1.6 or 1.7. Main java directory  will be install in /usr/lib/jvm.
#
# Params:
# ---------
#	$type 		- jdk or jre
#	$arc		- i586 or x64
#	$version	- version of java package
#	$os		- should only be linux for now
#
# It is import that you match the params with the java package you downloaded from oracle.
#
# For example, if you downloaded the ‘jdk-7u21-linux-x64.tar.gz’, your params should be:
#
# type		=> “jdk”
# arc 		=> “x64“
# version	=> “7u21“
# os		=> “linux”
#
# Usage:
# --------
# class { "oracle_java":
#	type 		=> "<type>",
#	arc 		=> "<arc>,
#	version		=> "<version>",
#	os		=> "linux",
# }

class oracle_java (
	$type 		= "jdk",
	$arc 		= "x64",
	$version	= "7u25",
	$os			= "linux",
	$java_temp_dir = "/tmp_javainstaller"
	) 
{

	require oracle_java::params

	$jvm_path = $oracle_java::params::jvm_path
	$java_file = $oracle_java::params::java_file
	$java_dir = $oracle_java::params::java_dir
	$unrar_command = $oracle_java::params::unrar_command
	$exec_javalink = $oracle_java::params::exec_javalink
	$exec_javawslink = $oracle_java::params::exec_javawslink
	$exec_javaclink = $oracle_java::params::exec_javaclink	

	#If Mac, install DMG:
	if $osfamily == "Darwin" {

		file { "${java_temp_dir}":
			ensure 		=> directory,
			owner		=> root,
			group 		=> wheel,
			mode 		=> 775,
		}

		file { "${java_temp_dir}/java.dmg":
			ensure 		=> present,
			source		=> "puppet:///modules/oracle_java/${type}-${version}-${os}-${arc}.dmg",
			require		=> File[ "${java_temp_dir}" ],
		}

		package { "Logger Lite ${version}":
			ensure 			=> installed,
			source			=> "${java_temp_dir}/java.dmg",
			require			=> File[ "${java_temp_dir}/java.dmg" ],
		}
	}
	elsif $osfamily == "windows" {				
	
		$lock_file = "${java_file}installed"
	
		file { "${java_temp_dir}":
			ensure 		=> directory,
		}
	
		file { "${java_temp_dir}/${java_file}":
			ensure 	=> present,
			source	=> "puppet:///modules/oracle_java/${java_file}",
			require => File[ "${java_temp_dir}" ],
		}

		file { "${jvm_path}/${java_dir}":
			ensure  => directory,
		}
		
		exec { "install_jdk":
			command	=> "cmd.exe /c START /WAIT ${java_temp_dir}/${java_file} /s INSTALLDIR=\"${jvm_path}\\${java_dir}\" /L ${java_temp_dir}/${type}_${version}_${os}_install.log",			
			require => [File[ "${java_temp_dir}/${java_file}" ] , File[ "${jvm_path}/${java_dir}" ]],
			path 	=> $::path,
			creates => "${jvm_path}/${java_dir}/bin/java.exe",
		}				
	}
	else{

		file { "$jvm_path":
			ensure 	=> directory,
			mode	=> '755',
			owner	=> 'root',
		}

		file { "${jvm_path}/${java_file}":
			ensure 	=> present,
			source	=> "puppet:///modules/oracle_java/${java_file}",
			require	=> File[ $jvm_path ],
		}

		exec { "untar_jdk":
			command	=> $unrar_command,
			path 	=> "/bin:/sbin:/usr/bin:/usr/sbin",
			unless	=> "test -e ${jvm_path}/${java_dir}",
			cwd		=> $jvm_path,
			require => File[ "${jvm_path}/${java_file}" ],
		}

		exec {'java_link':
			command	=> $exec_javalink,
			path 	=> "/bin:/sbin:/usr/bin:/usr/sbin",
			require	=> Exec [ "untar_jdk" ]
		}

		exec {'javaws_link':
			command	=> $exec_javawslink,
			path 	=> "/bin:/sbin:/usr/bin:/usr/sbin",
			require	=> Exec [ "untar_jdk" ]
		}

		exec {'javac_link':
			command	=> $exec_javaclink,
			path 	=> "/bin:/sbin:/usr/bin:/usr/sbin",
			require	=> Exec [ "untar_jdk" ]
		}
	}
}
