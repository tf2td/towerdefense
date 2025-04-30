Pakrat v0.95  by Rof (rof@mellish.org.uk)

2nd April 2006

A program for managing Half-Life 2 BSP PAK archives

---------------------------------------------------


What is Pakrat?

Pakrat is a graphical replacement for the standard bspzip program, that allows you to
view, add, and delete files that are stored inside compiled HL2 map (.BSP) files.
This allows you to embed custom texture, sound, and model files into a BSP file. The
embedded files will be automatically loaded from the map when the map is loaded by the
game, and so you do not have to distribute the custom files seperately.

Pakrat has the ability to scan the BSP file to find which custom files are used
in the map, and add them automatically. Files may also be added manually.


Who would use Pakrat?

Pakrat is only of interest to people producing new maps for HL2, HL2DM, and CS:S (and other
mods) that wish to use custom texture, sound, and/or model files in their maps. Pakrat only works with Source-engine BSP map files.


Installation

Pakrat is a Java application, and so requires the Java Runtime Environment (version 1.5.0 
or later) to be installed. If you do not already have this installed, the Windows version
can be downloaded from the Java website:

http://java.sun.com/j2se/1.5.0/

it is a 10.X Mb download. 

Note: you may be required to restart your computer to complete installation of the JRE.
Note: Pakrat is a Java application, and thus won't work as an Applet in a web browser.
Note: If you already have a later version of the JRE installed, Pakrat will work fine.

Once Java is installed, Pakrat can be installed by copying the Pakrat.jar file to any
convenient folder, such as the /SourceSDK/bin folder.

Run Pakrat by double clicking on the Pakrat.jar file. If Java is installed properly, the
program will start. If you see a Windows "choose the program you want to open the file
Pakrat.jar" message, or a message that the Main Class cannot be found, try restarting
windows to ensure that the Java installation has completed.

If you have .jar files associated with another program (e.g., WinRAR), you may also
run Pakrat by double clicking on the pakrat.bat batch file.

You can also run Pakrat from the command line, with the command "java -jar pakrat.jar".
This method takes an optional parameter, the initial map file to load.


Tutorial - an example of using Pakrat automatially

In many cases, Pakrat can be used in automatic mode. To do so, load the map using the
"Load BSP" menu option. Now press the "Auto" button at the bottom right. The map will
be scanned for any custom content used, and if found, a message will ask whether to
add those files to the Pak. Press "Yes", and then save the map using the "Save BSP"
menu item. The map file will be overwritten with a new version containing the custom
files.

See the "scan and auto scan" section below for full details of how the scanning feature
works.


Tutorial - an example of using Pakrat manually

Say you have a compiled HL2 map, "test1.bsp". The map uses two custom materials, named
"bluewall1.vmt" and "bluewall2.vmt", and one custom texture file, "bluewall.vtf". The custom
files are located in the directory "/materials/blue" relative to the "hl2" base folder.

To insert the files, run Pakrat and select the "test1.bsp" map. A list of files already in
the map's pak archive will be shown (if the map uses env_cubemaps, and the "buildcubemaps"
command has been run in-game, the list may be quite long). Now press the "Add" button at
the bottom of the main window, and a file selector will appear. Locate the custom texures;
if you wish, you may add multiple files at once by using ctrl+click, and may select folders
to include all files in that directory. Press "Open", and for each file selected a message
will appear: Fix-up path to "materials/blue/XXXXXXX.XXX". Choose "yes" for each file, or
"Yes to All" to skip the dialog.

At the end of the file list, there should be now three new entries: "bluewall1.vmt",
"bluewall2.vmt", and "bluewall.vtf". The pathname of each file should be "materials/blue".
Now go to the "File" menu, and choose "Save BSP". The file selector will appear. Press the
"Save" button, and the "test1.bsp" file will be overwritten with a new version, containing
the custom textures.

The file "test1.bsp" now can be distributed. You may verify that the map contains the
custom textures by renaming (or deleting) the custom file from disk, and loading the map
in HL2. If the custom textures show properly, then they are properly embedded in the map
file. 

Note that, if you recompile the map, you must re-add the custom textures to the .bsp file.
For this reason, it is best to add the custom textures just before distributing the final
map file.

You may also add files to the Pak by dragging-and-dropping files from Windows Explorer, or
automatically determine which files need to be included in the Pak by using the Auto Scan
feature (see below).


Details of operation

On startup, Pakrat opens a small console window. This console shows what operation Pakrat
is currently performing, and shows any error message encountered, but can otherwise be
ignored.

Unless a filename was passed to Pakrat on the command line, Pakrat will present a file
dialog to choose the map file to open. Locate any HL2 map (*.bsp) file to load it.
Once the map is loaded, the main window displays a list of all files located in the map
file's Pak archive. This archive may contain many files. Usually, all HL2 map file contain
at least one file, "cubemapdefault.vtf". This is the default cubemap (environment map)
texture for the map, and is actually a low-resolution copy of the map's skybox.
If the map has been loaded into HL2 and the command "buildcubemaps" performed, the pak
will also contain texture and material files relating to reflective materials used in the
map, and for each env_cubemap present in the map.

The main window display is a table, with a row for each file in the Pak archive. (The list
may be switched to a directory-tree like view using the View menu.)

The columns of the table are:

"In" : This column contains a checkmark for files that are currently in the loaded map's
Pak. If you have added new files to the Pak, and not yet saved the map file, the new file's
In checkmark will be blank.

"Filename": This is the filename of the file, as stored in the Pak. This will be blue
for files that have been added to be Pak, but the BSP file has not yet been saved.

"Pathname": This is the filepath of the file, as stored in the pak. The path is usually
relative the current Game Root directory (see below). Note: All backslash characters (\)
are converted to forward-slash characters (/) in this field. This is what the game expects
to see.

"Size": This is the size of the file, in bytes.

"Type": This is the type of the file, as derived from the filename, as shown in this table:

      Extension		Type		
	.vmt		Material
	.vtf		Texture
	.mdl		Model
	.vtx		Model (vertex mesh data)
	.vvd		Model (vertex data)
	.phy		Model (physics collision data)
	.wav		Sound
	.mp3		Sound
	.txt		Text

You can sort the file list by clicking on column headers. Click once to sort by accending
order, click again to sort in decending order. Use Ctrl+click to sort by multiple headings.

Above the file list is the menu bar. This has three menus:

File Menu:

"Load BSP": This loads a new map file. Any unsaved changes to the current file are lost.

"Save BSP": This saves the current map file. All changes to the Pak file are written
to disk. The program will prompt for confirmation if an already existing map file is
choosen. If you save a map with the same name and location from that it was loaded, a
backup file (<mapname>.bsp.bak) will be created. 

"Preferences": This sets the current Game Root directory, and an option to always, never,
or to ask whether to perform path fixup (see below) when adding a new file to the Pak. It also sets whether optional extra files will be scanned for by the Scan and Autoscan features.

"Quit": This quits Pakrat.

View Menu:

"As Tree":  This shows the list of embedded files as a directory-tree structure. Choose
again to switch back to the table list.

"Sort":  Sorts the file list by filename, path, file type, file size, or nothing. Note
that you can also sort the list by clicking on the table column headers.

Help Menu:

"Console": This re-shows the console window (if it has been closed).

"About Pakrat": This gives brief help information for Pakrat.

Below the file list are six buttons. If a file in the list above is selected, all 5
buttons can be used; otherwise, only the Add button is active. The buttons are:

"View": This views the contents of the selected file. Material (.vmt) files are displayed
as text. Texture (.vtf) files show a summary of the texture's properties (size, encoding
method, etc.), and a bitmap of the contents. Note that some texture files may contain
multiple frames or faces, and these can be viewed with the controls to the left.
Model (.mdl) files show a summary of the file and any material files referenced from
within it. Unrecognised files are shown as a hex dump or ASCII text.

"Edit": This allows the editing of the selected file's filename and path. This does not
affect the name, path, or contents of the individual file on disk, but changes the reference
to the file as stored in the map's Pak. Usually the only reason to change these values would
be to alter the stored path of the file (see path fixup, below).

"Add": This adds a file to the Pak. Note that by using shift-click or ctrl-click in the file
chooser dialog, you may add multiple files at once, and choosing a directory will recursively
add all files in that directory and any subdirectories.

You may also add files to the Pak by dragging-and-dropping from any Windows file window
onto Pakrat's file list.

Nothing is actually written to the map file until the "Save BSP" menu option is used.

"Delete": This deletes a file from the Pak. As for the Add button, the map file is not changed until the "Save BSP" menu item is used.

"Save": This extracts a file from the Pak, and saves it to disk.

"Scan": This opens the scan file window (see below).

"Auto":	This scans and automatically adds any used files to the Pak (see below).


Path fixup

Path fixup is necessary to allow HL2 to find the custom files embedded in the .bsp file,
when the .bsp file is loaded by the game. Say you are using a custom material for a HL2
map, located in the file:
"C:\Steam\SteamApps\<your steam username>\half life 2\hl2\materials\blue\bluewall1.vmt"
When HL2 loads the map, it first looks in the .bsp file's Pak archive, under the name:
"materials/blue/bluewall1.vmt". The "path" part of the file's Pak entry should thus be
"materials/blue". You can edit the entry manually (using the Edit button) to change this,
but an easier way is to use the automatic path-fixup. This can be done by setting the
"path-fixup on add file" option under Preferences to "Always" or "Ask" (to be prompted
for each file). If it is set to "Never", then path-fixup is not performed when a file
is added to the Pak.

Pakrat uses the Game Root directory setting (also on the preferences screen) to determine
the correct path during fixup. For a HL2 file, for example, the game root should be set as"
"C:/Steam/SteamApps/<your steam username>/half life 2/hl2" (note that this will vary
depending on where you installed Steam/Hl2). If you do not set the game root dir, Pakrat
will guess how to do fixup depending on the type of file you add: material and texture
files will have paths starting with "materials/", sound files with "sound/" and model
files with "models/". 


Scan and Auto Scan

Pakrat's Auto Scan feature searches the currently loaded BSP file for references to
external files that are used by the map. This includes the material files used to texture
the map geometry, the skybox textures, any model (.mdl) files used as prop_statics and other
entities, and any sound files referenced by entities. It also searches for a number of
standard files such as the map description text file.

Auto Scan also recursively checks for files referenced by the files it finds. For instance,
a model (.mdl) file may refer to several material (.vmt) files. Each of these materials will
reference one or more texture (.vtf) files. Model files are also created with a number of
associated vertex and physics data files. Auto Scan checks for the existance of all these.
Model files will also be checked for included sub-models and gib models.

Auto Scan cannot work correctly without a Game Root directory being set, that is, the base
directory of the game the map is designed for (see Path fixup, above). If you have not set
this in the Preferences screen, Pakrat will attempt to guess the correct directory from the
filename of the currently loaded map.

To start Auto Scan completely automatically, load a map file and press the "Auto" button.
After a short pause, a dialogue showing the number of files found on disk. Press "Yes" to
add them to the Pak.

If no files are found, you may have not set the game root directory correctly. 

To run a scan manually, load a map and press the Scan button.  A new window will appear.
You can alter the Game Root directory to use by typing in the "Gamedir" box at the top of
the new window. You may also choose from the drop-down list of previous settings.

For example, the gamedir setting for a HL2 single player map should typically be:
"C:/Steam/SteamApps/<your steam username>/half life 2/hl2"
or for a CounterStrike:Source map:
"C:/Steam/SteamApps/<your steam username>/counter-strike source/cstrike"
Note that these setting depend on the disk location of your Steam installation.

Once you have set the Gamedir directory, press the "Scan" button to start scanning
the map for file references. After a short pause, a list giving the filename, path,
type, and location of all files referenced in the map appears.

Note: if you have made changes to the Gamedir or to the relevant files on disk,
you may press the "Scan" button again to rescan the map and update the list.

The location for each file may be one of four values, which are colour-coded:

In Pak (green):		The file is stored in the map's Pak.
In List (blue):		The file is listed in the Pak list, but the BSP file has not
			 yet been saved.
On Disk (red):		The file isn't in the Pak, but has been found on disk by the autoscan.
Not Found (grey):	The file cannot be found in the Pak or on disk.

"In Pak" files are already saved in the map's Pak data. They do not require any further action.

"In List" files are listed in the Pak, but not yet stored in the BSP file. Once the current
map file is saved with the "Save BSP" option, they will be stored in the Pak.

"On Disk" files are not in the Pak, but have been found on disk relative to the currently
set gamedir (game root directory). These files may be selected by the checkbox in the "Add"
column to the right (by default, all On Disk files are selected after a scan).

"Not Found" cannot be found in the Pak or on disk. These files may be standard (non-custom)
files that are stored inside Steam's GCF files. Since Pakrat cannot read GCF files, it 
cannot tell if the file is missing or present. Note that all custom files will show as "not found" if the game root directory is set incorrectly.

Once the scan is complete, all "On Disk" files may be selected by the checkboxes in the
right-most column (the "Select All" and "Select None" buttons may also be used). If any
files are checked, pressing the "Add Selected" button adds all checked files to the Pak.
(If you have set the "ask for fixup" option, a message box will appear for each file added).
After this, the map is automatically rescanned and all "On Disk" files should change to
"In List". Use the main window's "Save BSP" option to save the BSP file and write all files
to the Pak. 

The "Done" button dismisses the Scan window.

If a row in the scan window is selected, the "Reference" button opens a sub-window showing
the name, type, diskname (filename by which the file is searched for on disk), file
location, and how the file was referenced in the map (i.e. any files that referenced this
file).


Extra files

A number of other files may be searched for when running Scan or Auto scan. These files may or may not be present, depending on the type of map. Which files are searched for may be
set using the "Preferences" menu item (by default, all of these files).

maps/<mapname>.nav
	The navigation mesh file for bots and hostages in CS:S maps.

maps/graphs/<mapname>.ain
	The AI node mesh for maps using NPCs.

maps/soundcache/<mapname>.cache
	The data cache for map-specific sounds.

maps/<mapname>.txt
	The map description text shown when the map is loaded.

resource/overviews/<mapname>.txt
	The level overview (inset map) parameters for CS:S and DoD:S maps. If found, this
	file is searched for the "material" keyword to find the material file used for the
	overview, and this material is searched for any texture files referenced.

scripts/soundscapes_<mapname>.txt
	The map's custom soundscape. If found, the file is searched for the "wave" keyword
	to find .wav files used in this soundscape.

Some of these files are redundent for certain map types; for instance, NAV files are
currently used only in maps made for CS:S. AIN files are autogenerated by the game engine
if not present, and may be embedded if you wish to prevent the "Node graph out of date, 
rebuilding" message appearing when the user loads the map for the first time. The sound cache file is also autogenerated when the map is first loaded, and may be embedded to
improve the initial map load time.



Navigation Mesh

If your bsp contains an embedded .nav file, saving the bsp will check the nav file to
ensure that it matches the bsp correctly. If it does not match, you will see a message:
"Nav file <filename>.nav version does not match this bsp file. Do you want to update it?"
Choose Yes to alter the embedded nav file to match the bsp. Doing this prevents the
"Navigation Mesh was built using a different version of this map" message that can appear
on loading the map.


Command-line options

pakrat [<filename>]
	Run Pakrat as normal. If a map filename is specified, the map is loaded.

pakrat -auto <basedir> <filename>	
	Run Pakrat without opening a window, and attempt an automatic scan-and-add of
	files used in the map <filename>.bsp using the game base directory of <basedir>.
	The map is saved automatically if any files are added. (For future integration
	of Pakrat with Hammer's expert compiling mode).

pakrat -list <filename>
	Print the directory of all files currently embedded into map <filename>.bsp

pakrat -dump <filename>
	Dump the whole Pak lump of map <filename>.bsp as an uncompressed zip file named
	<mapname>.bsp.zip. 

pakrat -save <filename> <pakfile>
	Find the file with the name <pakfile> in map <filename>.bsp's pak lump, and
	save it to disk.


Keyboard shortcuts

Main Window:

Ctrl+L		Load BSP file
Ctrl+S		Save BSP file
Ctrl+P		Preferences screen
Ctrl+T		Toggle between tree and list view of the files
Ctrl+Q		Quit Pakrat

Alt+V		View selected file(s)
Alt+E		Edit file parameters
Alt+A		Add file(s) to the Pak
Alt+Delete	Delete file(s) from the Pak
Alt+S		Save file(s) from the Pak to disk
Alt+C		Scan for used files
Alt+U		Start Auto Scan

Scan Window:

Alt+S		Start scan
Alt+E		Select all "On Disk" files
Alt+N		Deselect all files
Alt+R		Check references to current file
Alt+A		Add selected files to Pak
Alt+D		Dismiss scan window

-----------------------------------------------------------

http://www.geocities.com/cofrdrbob/