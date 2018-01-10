# TF2 Tower Defense #

TF2 Tower Defense is a modification to Valve's game Team Fortress 2. Basically you have to stop enemies from crossing a map by buying towers and building up defenses.

### Authors ###

TF2 Tower Defense was originally created by [floube](http://steamcommunity.com/profiles/76561198051789304/) and [mani](http://steamcommunity.com/profiles/76561198002201102/). It is currently maintained by [Hurp Durp](http://steamcommunity.com/profiles/76561198014050007).

Plugin - [floube](http://steamcommunity.com/profiles/76561198051789304/), [Benedevil](http://steamcommunity.com/profiles/76561198056589941), [Hurp Durp](http://steamcommunity.com/profiles/76561198014050007)
 
Maps - [mani](http://steamcommunity.com/profiles/76561198002201102/), [fatboy](http://steamcommunity.com/profiles/76561197994348901/), [Berry](http://steamcommunity.com/profiles/76561198030362593/)

### Requirements ###

 * Dedicated Team Fortress 2 server (windows or linux)
 * MySQL/MariaDB server
 * Metamod + Sourcemod
 * [Socket](https://github.com/nefarius/sm-ext-socket)
 * [TF2Items](https://forums.alliedmods.net/showthread.php?p=1050170)
 * [Steamtools](https://forums.alliedmods.net/showthread.php?t=170630)
 * [TF2Attributes](https://forums.alliedmods.net/showthread.php?t=210221)


### Installation ###

1. Create a dedicated TF2 server and install metamod + sourcemod, and the extensions and plugins above. Ensure that the server and plugins work before continuing.
2. Download the [latest release](https://github.com/tf2td/towerdefense/releases) of TF2TD.
3. On your MySQL/MariaDB server, create a new `towerdefense` database and user. Import the `db_schema.sql` file from the download into your database.
4. Add the database information to your sourcemod `databases.cfg` file (an example can be found [here](addons/sourcemod/configs/databases_example.cfg)).
5. Copy [`towerdefense.cfg`](cfg/towerdefense.cfg) to your server's `tf/cfg` folder. This file has settings that need to be executed when the server starts. Add the following to the end of your server's `cfg/server.cfg` file to do so:
   
   `exec towerdefense`
   
6. Copy the [`tf2tdcustom/`](custom) folder and its contents into your server's `tf/custom/` directory.
7. Copy `towerdefense.smx` to your sourcemod `tf/addons/sourcemod/plugins` folder.
8. Start your server with the map `td_firstone_v11b`. You should be able to connect and play if everything was set up correctly.


##### Trouble getting it working? Create an issue and provide your server log files for assistance. #####
