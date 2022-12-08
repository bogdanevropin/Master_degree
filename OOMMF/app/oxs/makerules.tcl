# FILE: makerules.tcl
#
# This file controls the application 'pimake' by defining rules which
# describe how to build the applications and/or extensions produced by
# the source code in this directory.
#
# Verify that this script is being sourced by pimake
if {[llength [info commands MakeRule]] == 0} {
    error "'[info script]' must be evaluated by pimake"
}
#
########################################################################
# Allow these Makerules to be ignored
global env
if {[info exists env(OOMMF_NO_BUILD_OXS)]} {
    return -code continue
}

set executables [list oxs]
# We do not yet distribute any Preisach models
#if {![info exists env(OOMMF_NO_BUILD_PREISACH)]} {
#    lappend executables opmsh
#}

# Base source modules
set objects {
    arrayscalarfield
    atlas
    chunkenergy
    director
    driver
    energy
    evolver
    ext
    exterror
    labelvalue
    lock
    mesh
    meshvalue
    output
    outputderiv
    oxs
    oxscmds
    oxsexcept
    oxsthread
    oxswarn
    scalarfield
    simstate
    threevector
    uniformscalarfield
    uniformvectorfield
    util
    vectorfield
}

# Extension modules.  Note that extsrcs includes relative path and .cc
# extension, whereas extobjs holds just bare base names.  Sort these
# so that any order-dependent bugs will at least be reproducible.
set extsrcs [lsort [glob -nocomplain -- [file join ext *.cc]]]
set extobjs {}
foreach src $extsrcs {
    lappend extobjs [file rootname [file tail $src]]
}

set lclsrcs [lsort [glob -nocomplain -- [file join local *.cc]]]
set lclobjs {}
foreach src $lclsrcs {
    lappend lclobjs [file rootname [file tail $src]]
}
set lcllibs {}
foreach src $lclsrcs {
   # Check src.rules files for external library info. If it exists, the
   # src.rules file is a Tcl script that sets the variable
   # Oxs_external_libs to a list of external libraries (stems only)
   # needed by the extension associated with src.cc.
   set fn "[file rootname $src].rules"
   if {[file readable $fn]} {
      set chan [open $fn r]
      set contents [read $chan]
      close $chan
      set slave [interp create -safe]
      $slave eval $contents
      if {![catch {$slave eval set Oxs_external_libs} libs]} {
	 set lcllibs [concat $lcllibs $libs]
      }
      interp delete $slave
   }
}

# CUDA extension modules.
set lclcusrcs [lsort [glob -nocomplain -- [file join local *.cu]]]
set lclcuobjs {}
foreach src $lclcusrcs {
    lappend lclcuobjs [file rootname [file tail $src]]
}

# Extension libraries
set lclincs {}
set lcllibs {}
foreach src [concat $lclsrcs $lclcusrcs] {
   # Check src.rules files for external library info. If it exists,
   # the src.rules file is a Tcl script that sets the variables
   # Oxs_external_includes and Oxs_external_libs to lists of external
   # include directories and external libraries (stems only),
   # respectively, needed by the extension associated with src.cc or
   # src.cu.
   set fn "[file rootname $src].rules"
   if {[file readable $fn]} {
      set chan [open $fn r]
      set contents [read $chan]
      close $chan
      set slave [interp create -safe]
      # Copy environment variables into slave
      $slave eval [list array set env [array get env]]
      # Make safe subcommands of "file" available in slave
      interp alias $slave file {} Oc_SafeFile
      # Evaluate .rules file
      $slave eval $contents
      # Export variables
      if {![catch {$slave eval set Oxs_external_includes} incs]} {
	 set lclincs [concat $lclincs $incs]
      }
      if {![catch {$slave eval set Oxs_external_libs} libs]} {
	 set lcllibs [concat $lcllibs $libs]
      }
      interp delete $slave
   }
}

if {[llength $lclcusrcs]>0} { 
   # There are CUDA source files (*.cu) on build list
   set configuration [Oc_Config RunPlatform]

   # Add base CUDA libraries to link list.
   if {[catch {$configuration GetValue CUDA_LIBS} cudalibs]} {
      error "Configuration value CUDA_LIBS not set; check environment\
             variables CUDA_HOME and/or CUDA_PATH are properly set."
   } else {
      set lcllibs [concat $lcllibs $cudalibs]
   }
   
   # If there are .cu files, then it is not unlikely that
   # some C++ files access CUDA C header files, so include
   # paths to those headers on the local include list.
   if {![catch {$configuration GetValue \
                   program_compiler_cuda_system_include_path} \
            cudapath]} {
      set lclincs [concat $lclincs $cudapath]
   }
}

set psrcs [lsort [glob -nocomplain -- [file join preisach *.cc]]]
set pobjs {}
foreach src $psrcs {
    lappend pobjs [file rootname [file tail $src]]
}

MakeRule Define {
    -targets		all
    -dependencies       [concat configure [Platform Specific appindex.tcl]]
}

MakeRule Define {
    -targets		configure
    -dependencies	[Platform Name]
}

MakeRule Define {
    -targets		[Platform Name]
    -dependencies	{}
    -script		{MakeDirectory [Platform Name]}
}

# Could use better support for this:
MakeRule Define {
    -targets		[Platform Specific appindex.tcl]
    -dependencies	[Platform Executables $executables]
    -script		[format {
        puts "Updating [Platform Specific appindex.tcl]"
        set f [open [Platform Specific appindex.tcl] w]
	foreach e {%s} {
            puts $f "
                Oc_Application Define {
                    -name		[list $e]
                    -version		1.2.1.4
                    -machine		[list [Platform Name]]
                    -file		[list [file tail \
					[Platform Executables [list $e]]]]
                }"
	}
        close $f
    } $executables]
}

set oxslibs {vf nb oc}
set fn [file join local makeextras.tcl]
if {[file readable $fn]} { source $fn }
MakeRule Define {
    -targets		[Platform Executables oxs]
    -dependencies	[concat [Platform Objects $objects] \
				[Platform Objects extinit] \
				[Platform Objects $extobjs] \
				[Platform Objects $lclobjs] \
				[Platform Objects $lclcuobjs] \
			        [Platform StaticLibraries $oxslibs] \
				[file join base tclIndex]]
    -script      [format {
                    Platform Link -obj {%s %s %s %s extinit} \
                       -lib {%s %s tk} \
                       -sub CONSOLE -out oxs
                  } $objects $extobjs $lclobjs $lclcuobjs $oxslibs $lcllibs]
}

MakeRule Define {
    -targets		[Platform Executables opmsh]
    -dependencies	[concat [Platform Objects $pobjs] \
			        [Platform StaticLibraries {nb oc}]]
    -script		[format {
			    Platform Link -obj {%s} \
			            -lib {nb oc tk} \
			            -sub WINDOWS -out opmsh
			} $pobjs ]
}

foreach obj $objects {
    set src [file join base $obj.cc]
    MakeRule Define {
        -targets	[Platform Objects $obj]
        -dependencies	[concat [list [Platform Name]] \
		[[CSourceFile New _ $src] Dependencies]]
        -script		[format {Platform Compile C++ -opt 1 \
			        -inc [[CSourceFile New _ %s] DepPath] \
			        -out %s -src %s
			} $src $obj $src]
    }
}
unset obj src

set path base
foreach src $extsrcs {
    set obj [file rootname [file tail $src]]
    MakeRule Define {
        -targets      [Platform Objects $obj]
        -dependencies [concat [list [Platform Name]] \
		[[CSourceFile New _ $src -inc $path] Dependencies]]
        -script       [format {Platform Compile C++ -opt 1 \
		-inc [[CSourceFile New _ %s -inc {%s}] DepPath] \
		-out %s -src %s
			} $src $path $obj $src]
    }
    unset obj
}
catch {unset src}
unset path

set path [concat base ext $lclincs]
foreach src $lclsrcs {
    set obj [file rootname [file tail $src]]
    MakeRule Define {
        -targets      [Platform Objects $obj]
        -dependencies [concat [list [Platform Name]] \
		[[CSourceFile New _ $src -inc $path] Dependencies]]
        -script       [format {Platform Compile C++ -opt 1 \
		-inc [[CSourceFile New _ %s -inc {%s}] DepPath] \
		-out %s -src %s
			} $src $path $obj $src]
    }
    unset obj
}
catch {unset src}
unset path

# CUDA files
set path [concat base ext $lclincs]
foreach src $lclcusrcs {
    set obj [file rootname [file tail $src]]
    MakeRule Define {
      -targets      [Platform Objects $obj]
      -dependencies [concat [list [Platform Name]] \
		[[CSourceFile New _ $src -inc $path] Dependencies]]
      -script       [format {Platform Compile CUDA \
		-inc [[CSourceFile New _ %s -inc {%s}] DepPath] \
		-out %s -src %s
			} $src $path $obj $src]
    }
    unset obj
}
catch {unset src}

set path [list]
foreach src $psrcs {
    set obj [file rootname [file tail $src]]
    MakeRule Define {
        -targets      [Platform Objects $obj]
        -dependencies [concat [list [Platform Name]] \
		[[CSourceFile New _ $src -inc $path] Dependencies]]
        -script       [format {Platform Compile C++ -opt 1 \
		-inc [[CSourceFile New _ %s -inc {%s}] DepPath] \
		-out %s -src %s
			} $src $path $obj $src]
    }
    unset obj
}
catch {unset src}
unset path

##########################################################################
# extinit.cc and extinit.o files.  These might disappear in the future.
set src [file join base extinit.cc]
set header [file join base ext.h]
MakeRule Define {
    -targets		[Platform Objects extinit]
    -dependencies	[concat [list [Platform Name]] $src \
		        	[[CSourceFile New _ $header] Dependencies]]
    -script		[format {Platform Compile C++ -opt 1 \
			        -inc [[CSourceFile New _ %s] DepPath] \
			        -out extinit -src %s
			} $src $src]
}
unset src header
set extsources {}
set src [file join base extinit.cc]
MakeRule Define {
    -targets            $src
    -dependencies       $extsources
    -script             [concat MakeOxsExtInit $src $extsources]
}
unset src extsources
##########################################################################

MakeRule Define {
    -targets		upgrade
    -script		{DeleteFiles \
             [file join ext atlasscalarfieldinit.cc] \
             [file join ext atlasscalarfieldinit.h]  \
             [file join ext atlasvectorfieldinit.cc] \
             [file join ext atlasvectorfieldinit.h]  \
             [file join ext filevectorfieldinit.cc] \
             [file join ext filevectorfieldinit.h]  \
             [file join ext planerandomvectorfieldinit.cc] \
             [file join ext planerandomvectorfieldinit.h]  \
             [file join ext randomvectorfieldinit.cc] \
             [file join ext randomvectorfieldinit.h]  \
             [file join ext rectangularregion.cc] \
             [file join ext rectangularregion.h]  \
             [file join ext rectangularsection.cc] \
             [file join ext rectangularsection.h]  \
             [file join ext scriptscalarfieldinit.cc] \
             [file join ext scriptscalarfieldinit.h]  \
             [file join ext scriptvectorfieldinit.cc] \
             [file join ext scriptvectorfieldinit.h]  \
             [file join ext sectionatlas.cc] \
             [file join ext sectionatlas.h]  \
             [file join ext standarddriver.cc] \
             [file join ext standarddriver.h]  \
             [file join ext uniformscalarfieldinit.cc] \
             [file join ext uniformscalarfieldinit.h]  \
             [file join ext uniformvectorfieldinit.cc] \
             [file join ext uniformvectorfieldinit.h]  \
             [file join base filelogger.tcl] \
             [file join base region.cc] \
             [file join base region.h]  \
             [file join base scalarfieldinit.cc] \
             [file join base scalarfieldinit.h]  \
             [file join base section.cc] \
             [file join base section.h]  \
             [file join base vectorfieldinit.cc] \
             [file join base vectorfieldinit.h]  \
    }
}

MakeRule Define {
    -targets            distclean
    -dependencies       clean
    -script             {DeleteFiles [Platform Name] base/extinit.cc}
}
 
MakeRule Define {
    -targets            clean
    -dependencies       mostlyclean
}
 
MakeRule Define {
    -targets            mostlyclean
    -dependencies       objclean
    -script             [format {eval DeleteFiles [concat \
			        [Platform Specific appindex.tcl] \
			        [Platform Executables {%s}]]
                         Recursive mostlyclean} $executables]
}

MakeRule Define {
    -targets            objclean
    -dependencies       {}
    -script             [format {
       eval DeleteFiles [Platform Objects {%s %s %s %s %s extinit}]
       eval DeleteFiles [Platform Intermediate {%s %s %s %s %s %s extinit}]
    } $objects $extobjs $lclobjs $lclcuobjs $pobjs \
      $objects $extobjs $lclobjs $lclcuobjs $pobjs $executables]
}

unset objects extobjs lclobjs lcllibs pobjs executables oxslibs
