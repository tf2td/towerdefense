VMEX (valve Map Extractor) is a .bsp to .vmf map decompiler for Half-Life 2 games (HL2, HL2DM, CS:S and DoD:S).
It also partially supports decompiling of .bsp files from Vampire: The Masquerade Bloodlines.

It requires the Java Runtime Environment 5.0 (aka 1.5.0) which can be downloaded from this page:
http://java.sun.com/j2se/1.5.0/download.jsp
By following the "Download JRE" link.

The decompiler can now be used from a graphical interface or the command line.
For the GUI, double-click on the vmex.bat file. Use the "Browse" button to select a .bsp file
to decompile, and the "Decompile" button to start decompilation. Note that any errors will appear
in the command-line window.

To run the decompiler from the command-line, invoke it with:

vmex <mapname.bsp>

or alternately:

java -jar vmex.jar <mapname.bsp>

For more information, see http://www.geocities.com/cofrdrbob/

Update v0.98g 14 Oct 2007

This update is a first pass at fixing problems with decompiling some HL2: Episode 2 maps. The slightly
changed prop_static lump in some maps is now handled. Some small problems with envmapped displacement
textures have been corrected. Note that some stuff may be missing, since several previously unused lumps
now contain data. Finding out what's missing will have to wait until the release of the Ep2 SDK update.

This update should also be able to decompile maps from TF2, though I have not yet tested this. Portal
maps can be decompiled with previous versions of Vmex without problems.

Update v0.98f 25 May 2007

Tiny update that fixes a displacement decompilation problem in some maps.

Update v0.98e 30 Sep 2006

Fixed a problem with displacement triangle tags that cause decompilation of the map dod_jagd to fail.
Also added a new option that outputs displacement brushes in an alternate form, which
should be less susceptible to rounding errors. Uncheck the "new disp. brushes" checkbox or use the
"-u" option to go back to the old method.

Update v0.98b 11 Jan 2006

Fixes handling of tool texture orientation, and better brush face assignment for overlays.

Update v0.98 8 Jan 2006

Two small changes: a bug with VMEX's handling of entities on some maps has been fixed (thanks to mapper
DarkTree for the bug report). Also, the decompiling process will now "crunch" the vertices of brush faces
that are very close together. This prevents some invalid brushes on some maps (e.g. d1_canal_11.bsp) that
Hammer would complain about when loading the decompiled file (the "solids were not loaded" error). I haven't
tested this option extensively yet, so if causes problems it can be switched off with the "-w" option or
by clearing the "crunch faces" checkbox on the GUI.

Update v0.97 1 Oct 2005

Now supports version 20 BSP files, as used in the DoD:S release. Note, the SDK does not yet support DoD:S,
so most textures and props will show as missing in Hammer. However, as soon as the SDK is updated, the maps
should show with all correct content.

Update v0.96 15 May 2005

This update fixes texture problems that occurred on displacement surfaces when decompiling the new CS:S map,
de_port. It also fixes some minor problems with clip brushes which were not being assigned correctly.

Update v0.95 7 Apr 2005

This update integrates the graphical interface (GUI) version that was previously available as v0.93G. To use
in GUI mode, invoke the program without specifying any arguments (e.g., by double-clicking on vmex.bat).
If options or a mapfile are given as arguments, the program runs from the command line as before.

This version also has partial support for decompiling of version 17 Source Engine bsp files as used by 
Vampire: The Masquerade Bloodlines.

Update v0.93 28 Feb 2005

This small update fixes a problem with maps that used certain overlay options, notably de_dust and de_train.

Update v0.92 8 Feb 2005

This update now outputs overlays as info_overlay entites. Their output can be disabled by using the -v
option. Overlays are currently only correctly associated with brush faces in brush-decompiling mode
(-m3, default). The also may sometimes be incorrectly orientated in Hammer (flipped or mirrored).
A bug which caused the last worldbrush in the map to not be written has been fixed.

Update v0.91 1 Feb 2005

This update fixes a (very rare) bug with texture handling on some maps.

Update v0.90 27 Jan 2005

Displacement surfaces are now decompiled. Generally these work very well, but a rare cases some maps show
small gaps between adjacent displacements. Alpha-blending of the surface textures is handled correctly.
Displacement decompiling can be turned off by setting the -h option; by default it is turned on.

This version of VMEX walks the map's BSP tree to determine which brushes are associated with which entities.
This method is much better than the previous guessing algorithm, and so it never needs to fall back to face-
decompiled brushes. 

A few maps give errors from a small number of invalid solids when loading into Hammer. The errors are
not usually fatal and the map can still be loaded.

This version fixes a bug in v0.80 that prevented decompiling maps with large numbers of planes (>32768).

Update v0.80 24 Jan 2005

This version adds a new decompiling mode (-m3) which is now the default. This mode decompiles the
map via brushes and planes, rather than map faces, producing a decompiled map which is much closer
to the original .vmf file. The files produced are also about half the size compared to those
produced using the other modes, making them much easier on Hammer.

The new mode also recovers the map's clip, hint and detail brushes. These are placed in visgroups for ease
of editing. 

Displacements are still not decompiled, and nor are their original brushes, so large gaps can
be found when decompiling maps which use them a lot (e.g. the d2_coast_* maps). Large brushes covered with
the yellow NODRAW texture indicate areas that should be covered with displacement surfaces.

Area portals are decompiled, but their brushes are not yet associated with their corresponding func_areaportal
entities. This will be fixed in future updates.

The new mode cannot always correctly assign brushes used by entities. If necessary, it will fall-back
to face-decompiled brushes for some entities. For some maps, brushes may be assigned to the wrong entity,
or not appear in the map. Check by decompiling using mode -m2 if you suspect something is wrong.

Because the new mode recovers almost all map brushes, it may be possible to recompile the decompiled
.vmf files (although rounding errors may cause leaks, and there may be other, more subtle problems).
For this reason, it is now possible for a map author to prevent decompilation with VMEX by setting
certain map options. See the FAQ (http://www.geocities.com/cofrdrbob/faq.html) for more information.

The locale-specific bug present in the previous version has now been fixed. VMEX will now always write
floating-point numbers in English format, no matter what the user's locale is set to. The workaround
(below) is no longer necessary.


Update v0.75a 19 Jan 2005

Added a temporary workaround for a bug that occurs if the user's locale uses comma-separated decimals.
This means that no decompiled maps will load in Hammer correctly.
The vmex.bat and vmex2.bat batch file now contain a switch to set Java to English when running vmex.
To do it manually, run vmex using the command:

java -Duser.language=en -jar vmex.jar <mapname.bsp>

There'll be a proper fix in the next version of vmex.

Update v0.75 18 Jan 2005

Added a -m<mode> switch to control the decompilation mode
 -m0  decompiles the map by original faces (as in previous versions).
This produces the smallest files, but there are sometimes missing faces that leave gaps.
 -m1 decompiles via split faces. This produces a large numbers of brushes and large files
(approx 60% - 80% bigger than -m0). However, (almost) all faces are present.
 -m2 (default) decompiles via original faces, unless it detects a missing one, in which case
it writes the corresponding split faces. This makes the vmf file somewhat bigger, while preventing
the gaps which occur in -m0 mode. -m2 mode is slower than the other two modes.

There is also now a -v switch which turns off a new vertex-checking method. This method prevents
most of the invalid solid and out-of-memory errors on loading the map in Hammer (not all, however).
If -v is set, the (slightly faster) method used in previous versions is used instead.

Update v0.72 16 Jan 2005

Fixed a bug with envmapped texture names that caused problems with the d2_coast_* maps.

Update v0.71 16 Jan 2005

Tiny bug fix update.

Update v0.7 16 Jan 2005

VMEX can now output env_cubemap entities
There are now a number of options that can be set on the command line, using:
vmex [options] <mapname.bsp>

  -d<value>	The thickness of the brushes created (default 1.0)
  -t<mode>	The texure output on the front face of a brush:
			-t0	white			-t2	orange grid
			-t1	black			-t3	the original face texture (default)
  -s<mode>	The texure output on the back faces of a brush:
			-t0	white		-t2	toolsinvisible (default)
			-t1	black		-t3	same as front face
  -r<value>	The precision (number of decimal places) to write floating-point values
  -o		Don't fixup origins of brush models
  -p		Don't output prop_statics
  -x		Don't fix texture names that refer to envmaps
  -c<value>	Env_cubemap output options
			-c0	no cubemaps		-c1	output cubemap location only
			-c<count>	write list of up to <count> sides tied to cubemap (default 8)

			
Update v0.6 14 Jan 2005

VMEX now supports decompilation of prop_statics


Initial release v0.5 13 Jan 2005



VMEX v0.98e 309 Sept 2006  rof@mellish.org.uk