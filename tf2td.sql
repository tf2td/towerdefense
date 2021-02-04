-- phpMyAdmin SQL Dump
-- version 4.5.1
-- http://www.phpmyadmin.net
--
-- Host: 127.0.0.1
-- Generation Time: Nov 23, 2017 at 02:43 AM
-- Server version: 10.1.10-MariaDB
-- PHP Version: 5.6.19

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `tf2td`
--

-- --------------------------------------------------------

--
-- Table structure for table `achievement`
--

CREATE TABLE `achievement` (
  `achievement_id` int(11) NOT NULL,
  `name` int(11) NOT NULL COMMENT 'The achievements name.',
  `description` int(11) NOT NULL COMMENT 'The achievements description.',
  `experience` int(11) NOT NULL COMMENT 'Amount of experience gained when achieving this.',
  `image` int(11) NOT NULL COMMENT 'The link to the achievements image.'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `config`
--

CREATE TABLE `config` (
  `config_id` int(11) NOT NULL,
  `variable` varchar(128) NOT NULL COMMENT 'The console variable.',
  `value` varchar(128) NOT NULL COMMENT 'The value to set the variable to.'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------


--
-- Table structure for table `map`
--

CREATE TABLE `map` (
  `map_id` int(11) NOT NULL,
  `name` varchar(128) NOT NULL COMMENT 'The maps name.',
  `teleport_ground` varchar(128) NOT NULL COMMENT 'Location of ground waves.',
  `teleport_air` varchar(128) NOT NULL COMMENT 'Location of air waves.',
  `teleport_tower` varchar(128) NOT NULL COMMENT 'Location of the tower after bought.',
  `respawn_wave_time` int(11) NOT NULL COMMENT 'Time between waves (in seconds).',
  `player_limit` int(11) NOT NULL DEFAULT '4',
  `wave_start` int(11) NOT NULL COMMENT 'The wave index to start with.',
  `wave_end` int(11) NOT NULL COMMENT 'The wave index to end with.'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `map`
--

INSERT INTO `map` (`map_id`, `name`, `teleport_ground`, `teleport_air`, `teleport_tower`, `respawn_wave_time`, `player_limit`, `wave_start`, `wave_end`) VALUES
(1, 'td_firstone_v11', '560 -1795 -78 0 90 0', '560 -1795 131 0 90 0', '666 -626 -2 0 0 0', 30, 4, 66, 130),
(2, 'td_firstone_v11b', '560 -1795 -78 0 90 0', '560 -1795 131 0 90 0', '666 -626 -2 0 0 0', 30, 4, 66, 130),
(3, 'td_rampant_v2d', '165 1665 35 0 180 0', '165 1665 35 0 180 0', '-400 1083 155 0 90 0', 30, 4, 1, 65),
(4, 'td_cavern_v4a', '-1145 1514 -340 0 -90 0', '-1145 1514 -340 0 -90 0', '250 400 130 0 0 0', 30, 4, 1, 65),
(5, 'td_swampy_a6', '-1470 900 -442 0 -90 0', '-1470 900 -442 0 -90 0', '-61 1015 -350 0 90 0', 30, 4, 1, 65);

-- --------------------------------------------------------

--
-- Table structure for table `metalpack`
--

CREATE TABLE `metalpack` (
  `metalpack_id` int(11) NOT NULL,
  `map_id` int(11) NOT NULL COMMENT 'The map.',
  `metalpacktype_id` int(11) NOT NULL COMMENT 'The metalpacks type.',
  `metal` smallint(6) NOT NULL COMMENT 'The amount of metal of the pack.',
  `location` varchar(128) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `metalpack`
--

INSERT INTO `metalpack` (`metalpack_id`, `map_id`, `metalpacktype_id`, `metal`, `location`) VALUES
(1, 1, 1, 400, '1100 -1200 -90'),
(2, 1, 1, 400, '1370 -640 -85'),
(3, 1, 1, 400, '860 -70 -80'),
(4, 1, 1, 400, '-400 -920 -108'),
(5, 1, 2, 400, '120 -5 -80'),
(6, 3, 1, 400, '-1377 1891 45'),
(7, 3, 1, 400, '-2370 2369 269'),
(8, 3, 1, 400, '831 1821 525'),
(9, 3, 1, 400, '192 448 269'),
(10, 3, 2, 400, '192 448 269'),
(11, 4, 1, 400, '-220 660 -145'),
(12, 4, 1, 400, '1435 1220 -275'),
(13, 4, 1, 400, '-740 1100 -405'),
(14, 4, 1, 400, '-2100 1313 -150'),
(15, 4, 2, 400, '2660 1130 170'),
(16, 5, 1, 400, '-70 1018 -350'),
(17, 5, 1, 400, '658 1241 -390'),
(18, 5, 1, 400, '1223 -1225 -430'),
(19, 5, 1, 400, '-67 -571 -460'),
(20, 5, 2, 400, '-67 -571 -460');

-- --------------------------------------------------------

--
-- Table structure for table `metalpacktype`
--

CREATE TABLE `metalpacktype` (
  `metalpacktype_id` int(11) NOT NULL,
  `type` varchar(64) NOT NULL COMMENT 'The metalpack type.'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `metalpacktype`
--

INSERT INTO `metalpacktype` (`metalpacktype_id`, `type`) VALUES
(2, 'boss'),
(1, 'start');

-- --------------------------------------------------------

--
-- Table structure for table `multiplier`
--

CREATE TABLE `multiplier` (
  `map_id` int(11) NOT NULL COMMENT 'The map.',
  `multipliertype_id` int(11) NOT NULL COMMENT 'The multiplier type.',
  `price` int(11) NOT NULL COMMENT 'The initial price.',
  `increase` int(11) NOT NULL COMMENT 'The amount the price increases each time upgraded.'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `multiplier`
--

INSERT INTO `multiplier` (`map_id`, `multipliertype_id`, `price`, `increase`) VALUES
(1, 1, 2000, 1000),
(1, 2, 2000, 1000),
(1, 3, 2000, 1000),
(1, 4, 2000, 1000),
(1, 5, 2000, 1000),
(3, 1, 2000, 1000),
(3, 2, 2000, 1000),
(3, 3, 2000, 1000),
(3, 4, 2000, 1000),
(3, 5, 2000, 1000),
(4, 1, 2000, 1000),
(4, 2, 2000, 1000),
(4, 3, 2000, 1000),
(4, 4, 2000, 1000),
(4, 5, 2000, 1000),
(5, 1, 2000, 1000),
(5, 2, 2000, 1000),
(5, 3, 2000, 1000),
(5, 4, 2000, 1000),
(5, 5, 2000, 1000);

-- --------------------------------------------------------

--
-- Table structure for table `multipliertype`
--

CREATE TABLE `multipliertype` (
  `multipliertype_id` int(11) NOT NULL,
  `type` varchar(64) NOT NULL COMMENT 'The multiplier type.'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `multipliertype`
--

INSERT INTO `multipliertype` (`multipliertype_id`, `type`) VALUES
(1, 'bullet'),
(5, 'crit'),
(3, 'explosion'),
(2, 'fire'),
(4, 'sentry');

-- --------------------------------------------------------

--
-- Table structure for table `player`
--

CREATE TABLE `player` (
  `player_id` int(11) NOT NULL,
  `name` varchar(64) NOT NULL COMMENT 'The players name.',
  `steamid64` varchar(32) NOT NULL COMMENT 'The players 64-bit SteamID.',
  `ip` varchar(32) NOT NULL COMMENT 'The players IPv4 address.',
  `first_server` int(11) NOT NULL COMMENT 'The first server the player connected to.',
  `last_server` int(11) DEFAULT NULL COMMENT 'The last server the player connected to.',
  `current_server` int(11) DEFAULT NULL COMMENT 'The current server the player is connected to.',
  `experience` int(11) NOT NULL DEFAULT '0' COMMENT 'The players current experience.',
  `level` int(11) NOT NULL DEFAULT '0' COMMENT 'The players current level.'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `player_achievement`
--

CREATE TABLE `player_achievement` (
  `player_id` int(11) NOT NULL,
  `achievement_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `player_ban`
--

CREATE TABLE `player_ban` (
  `player_ban_id` int(11) NOT NULL,
  `player_id` int(11) NOT NULL COMMENT 'The banned player.',
  `banner` varchar(32) NOT NULL COMMENT 'The banners 64-bit SteamID.',
  `reason` varchar(160) NOT NULL COMMENT 'The ban reason.',
  `time` datetime NOT NULL COMMENT 'The time of the ban happened.',
  `expire` datetime NOT NULL COMMENT 'When the ban expires.',
  `active` enum('not active','active') NOT NULL DEFAULT 'active' COMMENT 'If the ban is still actiive.'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `player_config`
--

CREATE TABLE `player_config` (
  `player_id` int(11) NOT NULL COMMENT 'The player.'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `player_immunity`
--

CREATE TABLE `player_immunity` (
  `player_id` int(11) NOT NULL,
  `immunity` int(11) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `player_stats`
--

CREATE TABLE `player_stats` (
  `player_id` int(11) NOT NULL COMMENT 'The player.',
  `map_id` int(11) NOT NULL COMMENT 'The map.',
  `kills` int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT 'Number of kills.',
  `assists` int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT 'Number of kill assists.',
  `deaths` int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT 'Number of deaths.',
  `damage` int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT 'Amount of damage dealt.',
  `objects_built` int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT 'Number of objects (sentries, etc.) built.',
  `towers_bought` int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT 'Number of bought towers.',
  `metal_pick` int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT 'Number of picked up metal.',
  `metal_drop` int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT 'Number of dropped metal.',
  `waves_played` int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT 'Number of waves played.',
  `wave_reached` int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT 'Number of wave reached.',
  `rounds_played` int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT 'Number of played rounds.',
  `rounds_won` int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT 'Number of rounds won.',
  `playtime` int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT 'Played time (in seconds).',
  `first_connect` datetime NOT NULL COMMENT 'Time of first connection.',
  `last_connect` datetime NOT NULL COMMENT 'Time of last connection.',
  `last_disconnect` datetime NOT NULL COMMENT 'Time of last disconnect.'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `server`
--

CREATE TABLE `server` (
  `server_id` int(11) NOT NULL,
  `name` varchar(128) DEFAULT NULL COMMENT 'The servers name.',
  `ip` varchar(32) NOT NULL COMMENT 'The servers IPv4 address.',
  `port` smallint(5) UNSIGNED NOT NULL COMMENT 'The servers port.',
  `version` varchar(32) DEFAULT NULL COMMENT 'The plugin version on this server.',
  `password` varchar(32) DEFAULT NULL COMMENT 'The servers current password.',
  `players` tinyint(3) UNSIGNED NOT NULL DEFAULT '0' COMMENT 'The current amount of players on the server.',
  `map_id` int(11) DEFAULT NULL COMMENT 'The servers current map.',
  `server_settings_id` int(11) DEFAULT NULL COMMENT 'The servers settings.',
  `reload_map` enum('no reload','reload') NOT NULL DEFAULT 'no reload' COMMENT 'If the map should be reloaded.',
  `created` datetime NOT NULL COMMENT 'The time this entry was created.',
  `updated` datetime NOT NULL COMMENT 'The last time this entry was updated.'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `server_settings`
--

CREATE TABLE `server_settings` (
  `server_settings_id` int(11) NOT NULL,
  `config_start` int(11) DEFAULT NULL COMMENT 'The config index to start with.',
  `config_end` int(11) DEFAULT NULL COMMENT 'The config index to end with.',
  `lockable` enum('not lockable','lockable') NOT NULL DEFAULT 'lockable' COMMENT 'If the server is lockable.',
  `loglevel` enum('None','Error','Warning','Info','Debug','Trace') NOT NULL DEFAULT 'Info' COMMENT 'The servers log level.',
  `logtype` enum('File','Console','File and console') NOT NULL DEFAULT 'File and console' COMMENT 'The servers log type.'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `server_stats`
--

CREATE TABLE `server_stats` (
  `server_id` int(11) NOT NULL,
  `connections` int(11) NOT NULL DEFAULT '0' COMMENT 'Number of connections.',
  `rounds_played` int(11) NOT NULL DEFAULT '0' COMMENT 'Number of played rounds.',
  `rounds_won` int(11) NOT NULL DEFAULT '0' COMMENT 'Number of rounds won.',
  `playtime` int(11) NOT NULL DEFAULT '0' COMMENT 'Total played time (in seconds) on this server.'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `tower`
--

CREATE TABLE `tower` (
  `tower_id` int(11) NOT NULL,
  `name` varchar(64) NOT NULL COMMENT 'The towers name.',
  `class` enum('Unknown','Scout','Sniper','Soldier','Demoman','Medic','Heavy','Pyro','Spy','Engineer') NOT NULL COMMENT 'The towers class.',
  `price` int(10) UNSIGNED NOT NULL COMMENT 'The towers price to buy.',
  `damagetype` enum('None','Bullet','Fire','Explosion','Melee','AoE') NOT NULL COMMENT 'The towers damagetype.',
  `description` varchar(1024) DEFAULT NULL COMMENT 'The towers description (use \\n for line breaks).'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `tower`
--

INSERT INTO `tower` (`tower_id`, `name`, `class`, `price`, `damagetype`, `description`) VALUES
(1, 'EngineerTower', 'Engineer', 3000, 'Melee', 'Will repair/upgrade any building. It has infinite metal supply.'),
(2, 'SniperTower', 'Sniper', 1750, 'Bullet', 'Deals medium damage with rapid shots and inifinite range. Can be tricky to place.'),
(3, 'MedicTower', 'Medic', 1800, 'AoE', 'Heals you if you get hurt. Dying is a major source of failure.'),
(4, 'GrenadeTower', 'Demoman', 2500, 'Explosion', 'Has a low rate of fire but deals very high damage within a radius.'),
(5, 'PyroTower', 'Pyro', 1500, 'Fire', 'Deals high damage. Enemies will begin to burn after passing it''s flames.'),
(6, 'JarateTower', 'Sniper', 2350, 'None', 'Throws jarate to enemies. Any damage deal mini-crits to affected enemies.'),
(7, 'AntiAirRocketTower', 'Soldier', 1600, 'Explosion', 'Fires rapid succession of rockets in the air.'),
(8, 'AntiAirFlareTower', 'Pyro', 1500, 'Fire', 'Fires rapid succession of flares in the air.'),
(9, 'CrossbowTower', 'Medic', 2750, 'Bullet', 'Fires rapid successions of bolts which will heal you and damage enemies.'),
(10, 'FlareTower', 'Pyro', 2200, 'Fire', 'Has a slow rate of fire deals high damage (mini-crit if target is on fire) and eventually knockbacks.'),
(11, 'HeavyTower', 'Heavy', 2500, 'Bullet', 'Has a high rate of fire and deals medium to high damage.'),
(12, 'ShotgunTower', 'Scout', 1700, 'Bullet', 'Deals decent damage with a high rate of fire.'),
(13, 'KnockbackTower', 'Scout', 2350, 'Bullet', 'Knocks enemies back, especially when near them. Can be very powerful.'),
(14, 'RocketTower', 'Soldier', 2500, 'Explosion', 'Has a medium rate of fire and deals medium damage within a radius.'),
(15, 'RapidFlareTower', 'Pyro', 1950, 'Fire', 'Fire flares which will damage and knock enemies a bit in the air.'),
(16, 'BackburnerTower', 'Pyro', 2250, 'Fire', NULL),
(17, 'LochNLoadTower', 'Demoman', 2150, 'Explosion', NULL),
(18, 'MachinaTower', 'Sniper', 1550, 'Bullet', NULL),
(19, 'LibertyTower', 'Soldier', 2750, 'Explosion', NULL),
(20, 'JuggleTower', 'Soldier', 3200, 'Explosion', NULL),
(21, 'BushwackaTower', 'Sniper', 1250, 'Melee', NULL),
(22, 'NataschaTower', 'Heavy', 2450, 'Bullet', NULL),
(23, 'GuillotineTower', 'Scout', 1450, 'None', NULL),
(24, 'HomewreckerTower', 'Pyro', 1200, 'Melee', NULL),
(25, 'AirblastTower', 'Pyro', 2400, 'None', NULL),
(26, 'AoEEngineerTower', 'Engineer', 3450, 'AoE', NULL),
(27, 'KritzkriegTower', 'Medic', 2000, 'AoE', NULL),
(28, 'SlownessTower', 'Spy', 2300, 'AoE', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `towerlevel`
--

CREATE TABLE `towerlevel` (
  `tower_id` int(11) NOT NULL COMMENT 'The tower.',
  `level` int(10) UNSIGNED NOT NULL COMMENT 'The actual level.',
  `metal` int(10) UNSIGNED NOT NULL DEFAULT '1000' COMMENT 'The metal needed to upgrade to next level.',
  `weapon_id` int(11) NOT NULL COMMENT 'The weapon the tower gets at this level.',
  `attack` enum('None','Primary','Secondary') NOT NULL COMMENT 'The towers attack type.',
  `rotate` enum('no rotate','rotate') NOT NULL DEFAULT 'no rotate' COMMENT 'If the tower should target enemies and rotate to keep them in sight.',
  `pitch` float NOT NULL DEFAULT '0' COMMENT 'The pitch of the tower at this level.',
  `damage` float NOT NULL DEFAULT '1' COMMENT 'The scaling of damage done by the tower at this level.',
  `attackspeed` float NOT NULL DEFAULT '1' COMMENT 'The scaling of the towers attackspeed at this level.',
  `area` float NOT NULL DEFAULT '1' COMMENT 'The scaling of the towers area of effect at this level.'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `towerlevel`
--

INSERT INTO `towerlevel` (`tower_id`, `level`, `metal`, `weapon_id`, `attack`, `rotate`, `pitch`, `damage`, `attackspeed`, `area`) VALUES
(1, 1, 1500, 1, 'Primary', '', 45, 1, 0.25, 1),
(1, 2, 2000, 22, 'Primary', '', 45, 1, 0.5, 1),
(1, 3, 3300, 23, 'Primary', '', 45, 1, 0.75, 1),
(1, 4, 6000, 24, 'Primary', '', 45, 1, 1, 1),
(1, 5, 8000, 25, 'Primary', '', 45, 1, 2, 1),
(2, 1, 500, 2, 'Primary', '', 0, 1, 1, 1),
(2, 2, 800, 26, 'Primary', '', 0, 1.25, 1, 1),
(2, 3, 1200, 27, 'Primary', '', 0, 1.5, 1.25, 1),
(2, 4, 2500, 28, 'Primary', 'no rotate', 0, 1.5, 1.5, 1),
(3, 1, 500, 30, 'None', '', 0, 1, 1, 1),
(3, 2, 750, 29, 'None', '', 0, 1, 1, 1.5),
(3, 3, 1000, 3, 'None', '', 0, 1, 1, 2),
(4, 1, 900, 4, 'Primary', '', 0, 1.5, 1, 1),
(4, 2, 1400, 4, 'Primary', '', 0, 1.5, 1, 1),
(4, 3, 2000, 4, 'Primary', '', 0, 2, 1, 1),
(5, 1, 1650, 5, 'Primary', '', 0, 1, 1, 1),
(5, 2, 1950, 33, 'Primary', '', 0, 1.25, 1, 1),
(5, 3, 2500, 34, 'Primary', 'no rotate', 0, 1.3, 1, 1),
(6, 1, 2550, 6, 'Primary', '', 0, 1, 1, 1),
(6, 2, 1550, 35, 'Primary', '', 0, 1, 1.7, 1),
(7, 1, 1350, 7, 'Primary', '', -60, 1, 1, 1),
(7, 2, 2150, 36, 'Primary', '', -60, 1.25, 1.25, 1),
(7, 3, 3750, 37, 'Primary', '', -60, 1.5, 1.5, 1),
(7, 4, 5000, 38, 'Primary', '', -60, 2, 2, 1),
(8, 1, 1150, 8, 'Primary', '', -60, 1, 1, 1),
(8, 2, 1750, 39, 'Primary', '', -60, 1, 1.5, 1),
(8, 3, 2350, 40, 'Primary', '', -60, 1.1, 2, 1),
(9, 1, 1450, 9, 'Primary', '', 0, 1, 0.25, 1),
(9, 2, 2500, 9, 'Primary', '', 0, 1.1, 0.5, 1),
(9, 3, 3350, 41, 'Primary', '', 0, 1.3, 0.8, 1),
(10, 1, 1250, 8, 'Primary', '', 0, 1, 1, 1),
(10, 2, 2450, 39, 'Primary', '', 0, 1, 1.5, 1),
(10, 3, 3650, 40, 'Primary', '', 0, 1.35, 2, 1),
(11, 1, 1650, 10, 'Primary', '', 0, 1, 1, 1),
(11, 2, 3250, 42, 'Primary', '', 0, 1.2, 1.3, 1),
(11, 3, 5000, 43, 'Primary', '', 0, 1.5, 1.5, 1),
(11, 4, 5000, 43, 'Primary', '', 0, 1.75, 1.5, 1),
(12, 1, 1550, 11, 'Primary', '', 0, 1, 1, 1),
(12, 2, 2150, 45, 'Primary', '', 0, 1, 1.6, 1),
(12, 3, 2850, 46, 'Primary', '', 0, 1.4, 1.6, 1),
(12, 4, 2850, 47, 'Primary', 'no rotate', 0, 1.5, 1.6, 1),
(13, 1, 4250, 12, 'Primary', '', 0, 1, 0.5, 1),
(13, 2, 6000, 12, 'Primary', '', 0, 1.15, 0.75, 1),
(13, 3, 8000, 48, 'Primary', '', 0, 2, 1, 1),
(14, 1, 1250, 7, 'Primary', '', 0, 1, 1, 1),
(14, 2, 1850, 36, 'Primary', '', 0, 1.2, 1.2, 1),
(14, 3, 2250, 37, 'Primary', '', 0, 1.35, 1.3, 1),
(14, 4, 2850, 38, 'Primary', '', 0, 1.5, 1.6, 1),
(15, 1, 500, 8, 'Primary', '', 0, 1, 2, 1),
(15, 2, 1150, 39, 'Primary', '', 0, 1, 2.5, 1),
(15, 3, 2250, 39, 'Primary', '', 0, 1, 3, 1),
(15, 4, 3150, 40, 'Primary', '', 0, 1.5, 3.5, 1),
(16, 1, 750, 13, 'Primary', '', 0, 1, 1, 1),
(16, 2, 1300, 13, 'Primary', '', 0, 1.2, 1, 1),
(16, 3, 1800, 13, 'Primary', '', 0, 1.5, 1, 1),
(17, 1, 1000, 14, 'Primary', '', 0, 1, 1, 1),
(17, 2, 1300, 14, 'Primary', '', 0, 1.2, 1.1, 1),
(17, 3, 2100, 14, 'Primary', '', 0, 1.4, 1.35, 1),
(18, 1, 5000, 15, 'Primary', '', 0, 1, 1, 1),
(18, 2, 8250, 15, 'Primary', 'no rotate', 0, 2, 2, 1),
(19, 1, 250, 16, 'Primary', '', 0, 1, 1, 1),
(19, 2, 750, 16, 'Primary', '', 0, 1, 1.1, 1),
(19, 3, 1800, 16, 'Primary', '', 0, 1, 1.45, 1),
(20, 1, 1000, 7, 'Primary', '', 45, 1, 1, 1),
(21, 1, 1000, 17, 'Primary', '', 0, 1, 1, 1),
(21, 2, 1500, 17, 'Primary', '', 0, 1, 1.35, 1),
(21, 3, 2100, 17, 'Primary', '', 0, 1, 2, 1),
(22, 1, 2300, 18, 'Primary', '', 0, 1, 1, 1),
(22, 2, 3200, 18, 'Primary', '', 0, 1.15, 2, 1),
(23, 1, 1000, 19, 'Primary', '', 0, 1, 1, 1),
(24, 1, 1000, 20, 'Primary', '', 0, 1, 1, 1),
(25, 1, 1000, 5, 'Secondary', '', 0, 1, 1, 1),
(26, 1, 2000, 1, 'None', '', 0, 1, 1, 1),
(26, 2, 3000, 22, 'None', '', 0, 1, 1, 1.25),
(26, 3, 4000, 23, 'None', '', 0, 1, 1, 1.5),
(26, 4, 5000, 24, 'None', '', 0, 1, 1, 1.75),
(26, 5, 6000, 25, 'None', '', 0, 1, 1, 2),
(27, 1, 1000, 21, 'None', '', 0, 1, 1, 1),
(28, 1, 1000, 49, 'None', '', 0, 1, 1, 1);

-- --------------------------------------------------------

--
-- Table structure for table `wave`
--

CREATE TABLE `wave` (
  `wave_id` int(11) NOT NULL,
  `wavetype` int(11) NOT NULL COMMENT 'The waves type bit field.',
  `name` varchar(64) NOT NULL COMMENT 'The waves bot names.',
  `class` enum('Unknown','Scout','Sniper','Soldier','Demoman','Medic','Heavy','Pyro','Spy','Engineer') NOT NULL COMMENT 'The waves class.',
  `quantity` tinyint(3) UNSIGNED NOT NULL COMMENT 'Number of bots in this wave.',
  `health` int(11) NOT NULL COMMENT 'The waves bot health.'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `wave`
--

INSERT INTO `wave` (`wave_id`, `wavetype`, `name`, `class`, `quantity`, `health`) VALUES
(1, 0, 'WeakSniper', 'Sniper', 8, 100),
(2, 2, 'WeakSoldier', 'Soldier', 8, 125),
(3, 0, 'WeakHeavy', 'Heavy', 8, 275),
(4, 0, 'WeakEngineer', 'Engineer', 10, 300),
(5, 0, 'WeakHeavy', 'Heavy', 9, 425),
(6, 4, 'WeakSoldier', 'Soldier', 9, 375),
(7, 0, 'WeakHeavy', 'Heavy', 11, 475),
(8, 8, 'WeakSpy', 'Spy', 9, 395),
(9, 2, 'WeakScout', 'Scout', 10, 475),
(10, 0, 'WeakHeavy', 'Heavy', 10, 700),
(11, 1, 'TheDemoman', 'Demoman', 4, 2000),
(12, 0, 'LamePyro', 'Pyro', 9, 850),
(13, 0, 'LameSniper', 'Sniper', 10, 825),
(14, 0, 'LameDemoman', 'Demoman', 10, 850),
(15, 0, 'LamePyro', 'Pyro', 11, 850),
(16, 0, 'LameSniper', 'Sniper', 13, 700),
(17, 4, 'LameHeavy', 'Heavy', 14, 625),
(18, 8, 'LameSpy', 'Spy', 10, 725),
(19, 2, 'LameScout', 'Scout', 12, 575),
(20, 0, 'LameSniper', 'Sniper', 13, 850),
(21, 0, 'LamePyro', 'Pyro', 13, 875),
(22, 1, 'TheEngineer', 'Engineer', 4, 5975),
(23, 0, 'BadMedic', 'Medic', 8, 1975),
(24, 0, 'BadEngineer', 'Engineer', 9, 1675),
(25, 0, 'BadSoldier', 'Soldier', 10, 1575),
(26, 0, 'BadMedic', 'Medic', 10, 1675),
(27, 0, 'BadEngineer', 'Engineer', 12, 1325),
(28, 0, 'BadSoldier', 'Soldier', 13, 1225),
(29, 0, 'BadMedic', 'Medic', 10, 1875),
(30, 8, 'BadSpy', 'Spy', 9, 1575),
(31, 2, 'BadScout', 'Scout', 12, 1375),
(32, 0, 'BadSoldier', 'Soldier', 15, 1425),
(33, 1, 'TheSniper', 'Sniper', 4, 19975),
(34, 0, 'NewbieSniper', 'Sniper', 9, 2775),
(35, 0, 'NewbiePyro', 'Pyro', 8, 3375),
(36, 0, 'NewbieDemoman', 'Demoman', 10, 2775),
(37, 0, 'NewbieSniper', 'Sniper', 11, 2975),
(38, 0, 'NewbiePyro', 'Pyro', 11, 3175),
(39, 0, 'NewbieDemoman', 'Demoman', 13, 2775),
(40, 0, 'NewbieSniper', 'Sniper', 8, 5975),
(41, 8, 'NewbieHeavy', 'Heavy', 12, 3475),
(42, 2, 'NewbieScout', 'Scout', 12, 2975),
(43, 0, 'NewbiePyro', 'Pyro', 15, 3475),
(44, 1, 'TheMedic', 'Medic', 4, 33975),
(45, 0, 'AverageEngineer', 'Engineer', 9, 6975),
(46, 0, 'AverageSoldier', 'Soldier', 9, 7175),
(47, 0, 'AverageMedic', 'Medic', 10, 6975),
(48, 0, 'AverageEngineer', 'Engineer', 11, 6275),
(49, 0, 'AverageSoldier', 'Soldier', 11, 6475),
(50, 0, 'AverageMedic', 'Medic', 12, 5975),
(51, 2, 'AverageScout', 'Scout', 9, 6975),
(52, 8, 'AverageHeavy', 'Heavy', 9, 6975),
(53, 4, 'AverageSpy', 'Spy', 10, 7725),
(54, 0, 'AverageMedic', 'Medic', 12, 7475),
(55, 1, 'TheScout', 'Scout', 4, 44975),
(56, 0, 'GoodMedic', 'Medic', 9, 10975),
(57, 8, 'GoodSpy', 'Spy', 8, 8975),
(58, 8, 'GoodHeavy', 'Heavy', 8, 10975),
(59, 0, 'GoodScout', 'Scout', 9, 13475),
(60, 0, 'GoodSniper', 'Sniper', 10, 13975),
(61, 0, 'GoodHeavy', 'Heavy', 9, 16475),
(62, 0, 'fatboy', 'Engineer', 9, 16725),
(63, 4, 'berry', 'Scout', 8, 17975),
(64, 0, 'mani', 'Spy', 8, 18975),
(65, 8, 'floube', 'Soldier', 7, 17975),
(66, 0, 'WeakScout', 'Scout', 8, 125),
(67, 0, 'WeakSoldier', 'Soldier', 9, 175),
(68, 2, 'WeakMedic', 'Medic', 10, 275),
(69, 0, 'WeakHeavy', 'Heavy', 10, 325),
(70, 4, 'WeakDemoman', 'Demoman', 11, 300),
(71, 0, 'WeakPyro', 'Pyro', 9, 425),
(72, 32, 'WeakScout', 'Scout', 10, 475),
(73, 12, 'WeakSniper', 'Sniper', 6, 575),
(74, 16, 'WeakSpy', 'Spy', 7, 650),
(75, 1, 'TheDoctor', 'Medic', 1, 3000),
(76, 0, 'LameScout', 'Scout', 8, 775),
(77, 0, 'LameSoldier', 'Soldier', 8, 825),
(78, 16, 'LameSpy', 'Spy', 7, 775),
(79, 0, 'LameHeavy', 'Heavy', 9, 925),
(80, 32, 'LamePyro', 'Pyro', 9, 925),
(81, 2, 'LameMedic', 'Medic', 7, 975),
(82, 8, 'LameDemoman', 'Demoman', 7, 1075),
(83, 0, 'LameSniper', 'Sniper', 10, 1425),
(84, 4, 'LameScout', 'Scout', 8, 1475),
(85, 1, 'TheSharpshooter', 'Sniper', 1, 7500),
(86, 0, 'BadSoldier', 'Soldier', 9, 1475),
(87, 0, 'BadSpy', 'Spy', 10, 1525),
(88, 8, 'BadDemoman', 'Demoman', 7, 1225),
(89, 0, 'BadHeavy', 'Heavy', 9, 1725),
(90, 4, 'BadMedic', 'Medic', 7, 1675),
(91, 0, 'BadEngineer', 'Engineer', 11, 1875),
(92, 32, 'BadScout', 'Scout', 7, 1725),
(93, 0, 'BadDemoman', 'Demoman', 9, 1975),
(94, 32, 'BadMedic', 'Medic', 8, 1975),
(95, 1, 'TheEngineer', 'Engineer', 1, 1975),
(96, 0, 'AverageSoldier', 'Soldier', 11, 2275),
(97, 44, 'AverageSpy', 'Spy', 7, 2175),
(98, 0, 'AverageDemoman', 'Demoman', 8, 2975),
(99, 0, 'AverageHeavy', 'Heavy', 9, 3375),
(100, 12, 'AverageMedic', 'Medic', 7, 2875),
(101, 0, 'AverageEngineer', 'Engineer', 9, 3775),
(102, 32, 'AverageScout', 'Scout', 11, 3775),
(103, 32, 'AveragePyro', 'Pyro', 10, 3975),
(104, 0, 'AverageMedic', 'Medic', 10, 4475),
(105, 1, 'TheSpy', 'Spy', 1, 17500),
(106, 34, 'GoodScout', 'Scout', 7, 4475),
(107, 16, 'GoodSpy', 'Spy', 9, 4475),
(108, 0, 'GoodDemoman', 'Demoman', 11, 5225),
(109, 0, 'GoodEngineer', 'Engineer', 10, 5475),
(110, 0, 'GoodMedic', 'Medic', 8, 5725),
(111, 36, 'GoodPyro', 'Pyro', 9, 5475),
(112, 32, 'GoodSoldier', 'Soldier', 8, 5975),
(113, 4, 'GoodMedic', 'Medic', 10, 6225),
(114, 0, 'GoodSpy', 'Spy', 9, 6975),
(115, 1, 'TheNoob', 'Scout', 1, 30000),
(116, 8, 'PremiumScout', 'Scout', 9, 5775),
(117, 12, 'PremiumSpy', 'Spy', 10, 5975),
(118, 0, 'PremiumDemoman', 'Demoman', 10, 7975),
(119, 2, 'PremiumEngineer', 'Engineer', 10, 7225),
(120, 40, 'PremiumMedic', 'Medic', 7, 6975),
(121, 0, 'PremiumPyro', 'Pyro', 8, 8975),
(122, 0, 'PremiumSoldier', 'Soldier', 8, 9225),
(123, 34, 'PremiumMedic', 'Medic', 9, 8475),
(124, 0, 'PremiumSpy', 'Spy', 7, 9975),
(125, 33, 'TheBeast', 'Soldier', 1, 49975),
(126, 6, 'OverpoweredScout', 'Scout', 8, 9975),
(127, 36, 'OverpoweredMedic', 'Medic', 8, 10975),
(128, 8, 'floube', 'Engineer', 9, 9975),
(129, 8, 'mani', 'Soldier', 10, 9975),
(130, 37, 'benedevil', 'Heavy', 4, 60000);

-- --------------------------------------------------------

--
-- Table structure for table `wavetype`
--

CREATE TABLE `wavetype` (
  `wavetype_id` int(11) NOT NULL,
  `type` varchar(64) NOT NULL COMMENT 'The wave type.',
  `bit_value` int(11) NOT NULL COMMENT 'The wave types binary value.'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `wavetype`
--

INSERT INTO `wavetype` (`wavetype_id`, `type`, `bit_value`) VALUES
(1, 'none', 0),
(2, 'boss', 1),
(3, 'rapid', 2),
(4, 'regen', 4),
(5, 'knockbackImmune', 8),
(6, 'air', 16),
(7, 'jarateImmune', 32);

-- --------------------------------------------------------

--
-- Table structure for table `weapon`
--

CREATE TABLE `weapon` (
  `weapon_id` int(11) NOT NULL,
  `name` varchar(96) NOT NULL COMMENT 'The weapons name.',
  `index` int(10) UNSIGNED NOT NULL COMMENT 'The weapons item index.',
  `slot` enum('Primary','Secondary','Melee','Grenade','Building','PDA','Item1','Item2') NOT NULL COMMENT 'The weapons slot.',
  `level` smallint(5) UNSIGNED NOT NULL DEFAULT '1' COMMENT 'The weapons level.',
  `quality` enum('Normal','Genuine','Rarity2','Vintage','Strange','Unusual','Unique','Community','Valve','Self-Made','Costumized') NOT NULL DEFAULT 'Normal' COMMENT 'The weapons quality.',
  `classname` varchar(64) NOT NULL COMMENT 'The weapons classname.',
  `attributes` varchar(512) NOT NULL COMMENT 'The weapons attribute string. (Format: "id1;value1;id2;value2")',
  `preserve_attributes` enum('no preserve','preserve') NOT NULL DEFAULT 'preserve' COMMENT 'If attributes of the weapon should be preserved (paint, level, etc.)'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `weapon`
--

INSERT INTO `weapon` (`weapon_id`, `name`, `index`, `slot`, `level`, `quality`, `classname`, `attributes`, `preserve_attributes`) VALUES
(1, 'Wrench', 7, 'Melee', 1, 'Normal', 'tf_weapon_wrench', '', 'preserve'),
(2, 'Sniper Rifle', 14, 'Primary', 1, 'Normal', 'tf_weapon_sniperrifle', '', 'preserve'),
(3, 'Medigun', 29, 'Secondary', 1, 'Normal', 'tf_weapon_medigun', '', 'preserve'),
(4, 'Grenade Launcher ', 19, 'Primary', 1, 'Normal', 'tf_weapon_grenadelauncher', '', 'preserve'),
(5, 'Flamethrower', 21, 'Primary', 1, 'Normal', 'tf_weapon_flamethrower', '', 'preserve'),
(6, 'Jarate', 58, 'Secondary', 1, 'Normal', 'tf_weapon_jar', '', 'preserve'),
(7, 'Rocket Launcher ', 18, 'Primary', 1, 'Normal', 'tf_weapon_rocketlauncher', '', 'preserve'),
(8, 'The Flare Gun ', 39, 'Secondary', 1, 'Normal', 'tf_weapon_flaregun', '', 'preserve'),
(9, 'Crusaders Crossbow', 305, 'Primary', 1, 'Normal', 'tf_weapon_crossbow', '', 'preserve'),
(10, 'Minigun', 15, 'Primary', 1, 'Normal', 'tf_weapon_minigun', '', 'preserve'),
(11, 'Scattergun', 13, 'Primary', 1, 'Normal', 'tf_weapon_scattergun', '', 'preserve'),
(12, 'Force-A-Nature', 45, 'Primary', 1, 'Normal', 'tf_weapon_scattergun', '', 'preserve'),
(13, 'The Backburner ', 40, 'Primary', 1, 'Normal', 'tf_weapon_flamethrower', '', 'preserve'),
(14, 'The Loch-n-Load', 308, 'Primary', 1, 'Normal', 'tf_weapon_grenadelauncher', '', 'preserve'),
(15, 'The Machina ', 526, 'Primary', 1, 'Normal', 'tf_weapon_sniperrifle', '', 'preserve'),
(16, 'The Liberty Launcher ', 414, 'Primary', 1, 'Normal', 'tf_weapon_rocketlauncher', '', 'preserve'),
(17, 'The Bushwacka ', 232, 'Melee', 1, 'Normal', 'tf_weapon_club', '', 'preserve'),
(18, 'Natascha', 41, 'Primary', 1, 'Normal', 'tf_weapon_minigun', '', 'preserve'),
(19, 'The Flying Guillotine ', 812, 'Secondary', 1, 'Normal', 'tf_weapon_cleaver', '', 'preserve'),
(20, 'Homewrecker ', 153, 'Melee', 1, 'Normal', 'tf_weapon_fireaxe', '', 'preserve'),
(21, 'The Kritzkrieg', 35, 'Secondary', 1, 'Normal', 'tf_weapon_medigun', '', 'preserve'),
(22, 'Festive Wrench', 329, 'Melee', 1, 'Normal', 'tf_weapon_wrench', '', 'preserve'),
(23, 'Silver Botkiller Wrench Mk.I', 795, 'Melee', 1, 'Normal', 'tf_weapon_wrench', '', 'preserve'),
(24, 'Gold Botkiller Wrench Mk.I', 804, 'Melee', 1, 'Normal', 'tf_weapon_wrench', '', 'preserve'),
(25, 'Golden Wrench', 169, 'Melee', 1, 'Normal', 'tf_weapon_wrench', '', 'preserve'),
(26, 'Festive Sniper Rifle', 664, 'Primary', 1, 'Normal', 'tf_weapon_sniperrifle', '', 'preserve'),
(27, 'Silver Botkiller Sniper Rifle Mk.I', 792, 'Primary', 1, 'Normal', 'tf_weapon_sniperrifle', '', 'preserve'),
(28, 'Gold Botkiller Sniper Rifle Mk.II', 966, 'Primary', 1, 'Normal', 'tf_weapon_sniperrifle', '', 'preserve'),
(29, 'Rust Botkiller Medigun Mk.I', 885, 'Secondary', 1, 'Normal', 'tf_weapon_medigun', '', 'preserve'),
(30, 'Carbonado Botkiller Medigun Mk.I', 903, 'Secondary', 1, 'Normal', 'tf_weapon_medigun', '', 'preserve'),
(31, 'Festive Grenade Launcher', 1007, 'Primary', 1, 'Normal', 'tf_weapon_grenadelauncher', '', 'preserve'),
(32, 'The Loose Cannon', 996, 'Primary', 1, 'Normal', 'tf_weapon_cannon', '', 'preserve'),
(33, 'The Backburner', 40, 'Primary', 1, 'Normal', 'tf_weapon_flamethrower', '', 'preserve'),
(34, 'Festive Backburner', 1146, 'Primary', 1, 'Normal', 'tf_weapon_flamethrower', '', 'preserve'),
(35, 'Festive Jarate', 1083, 'Secondary', 1, 'Normal', 'tf_weapon_jar', '', 'preserve'),
(36, 'Blood Botkiller Rocket Launcher Mk.I', 898, 'Primary', 1, 'Normal', 'tf_weapon_rocketlauncher', '', 'preserve'),
(37, 'Carbonado Botkiller Rocket Launcher Mk.I', 907, 'Primary', 1, 'Normal', 'tf_weapon_rocketlauncher', '', 'preserve'),
(38, 'Diamond Botkiller Rocket Launcher Mk.I', 916, 'Primary', 1, 'Normal', 'tf_weapon_rocketlauncher', '', 'preserve'),
(39, 'The Detonator', 351, 'Secondary', 1, 'Normal', 'tf_weapon_flaregun', '', 'preserve'),
(40, 'Festive Flare Gun', 1081, 'Secondary', 1, 'Normal', 'tf_weapon_flaregun', '', 'preserve'),
(41, 'Festive Crusader''s Crossbow', 1079, 'Primary', 1, 'Normal', 'tf_weapon_crossbow', '', 'preserve'),
(42, 'Natascha', 41, 'Primary', 1, 'Normal', 'tf_weapon_minigun', '', 'preserve'),
(43, 'Iron Curtain', 298, 'Primary', 1, 'Normal', 'tf_weapon_minigun', '', 'preserve'),
(44, 'The Huo Long Heatmaker', 811, 'Primary', 1, 'Normal', 'tf_weapon_minigun', '', 'preserve'),
(45, 'Silver Botkiller Scattergun Mk.I', 799, 'Primary', 1, 'Normal', 'tf_weapon_scattergun', '', 'preserve'),
(46, 'Gold Botkiller Scattergun Mk.I', 808, 'Primary', 1, 'Normal', 'tf_weapon_scattergun', '', 'preserve'),
(47, '	Diamond Botkiller Scattergun Mk.I', 915, 'Primary', 1, 'Normal', 'tf_weapon_scattergun', '', 'preserve'),
(48, 'Festive Force-A-Nature', 1078, 'Primary', 1, 'Normal', 'tf_weapon_scattergun', '', 'preserve'),
(49, 'Knife', 4, 'Melee', 1, 'Normal', 'tf_weapon_knife', '', 'preserve');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `achievement`
--
ALTER TABLE `achievement`
  ADD PRIMARY KEY (`achievement_id`);

--
-- Indexes for table `config`
--
ALTER TABLE `config`
  ADD PRIMARY KEY (`config_id`);

--
-- Indexes for table `map`
--
ALTER TABLE `map`
  ADD PRIMARY KEY (`map_id`),
  ADD UNIQUE KEY `name_UNIQUE` (`name`),
  ADD KEY `fk_map_wave_start_idx` (`wave_start`),
  ADD KEY `fk_map_wave_end_idx` (`wave_end`);

--
-- Indexes for table `metalpack`
--
ALTER TABLE `metalpack`
  ADD PRIMARY KEY (`metalpack_id`),
  ADD KEY `fk_metalpack_map_idx` (`map_id`),
  ADD KEY `fk_metalpack_metalpacktype_idx` (`metalpacktype_id`);

--
-- Indexes for table `metalpacktype`
--
ALTER TABLE `metalpacktype`
  ADD PRIMARY KEY (`metalpacktype_id`),
  ADD UNIQUE KEY `type_UNIQUE` (`type`);

--
-- Indexes for table `multiplier`
--
ALTER TABLE `multiplier`
  ADD PRIMARY KEY (`map_id`,`multipliertype_id`),
  ADD KEY `fk_multiplier_multipliertype_idx` (`multipliertype_id`);

--
-- Indexes for table `multipliertype`
--
ALTER TABLE `multipliertype`
  ADD PRIMARY KEY (`multipliertype_id`),
  ADD UNIQUE KEY `type_UNIQUE` (`type`);

--
-- Indexes for table `player`
--
ALTER TABLE `player`
  ADD PRIMARY KEY (`player_id`),
  ADD UNIQUE KEY `steamid64_UNIQUE` (`steamid64`),
  ADD KEY `fk_player_server_first_idx` (`first_server`),
  ADD KEY `fk_player_server_last_idx` (`last_server`),
  ADD KEY `fk_player_server_current_idx` (`current_server`);

--
-- Indexes for table `player_achievement`
--
ALTER TABLE `player_achievement`
  ADD PRIMARY KEY (`player_id`,`achievement_id`),
  ADD KEY `fk_player_achievement_achievement_idx` (`achievement_id`);

--
-- Indexes for table `player_ban`
--
ALTER TABLE `player_ban`
  ADD PRIMARY KEY (`player_ban_id`),
  ADD KEY `fk_player_ban_player_idx` (`player_id`);

--
-- Indexes for table `player_config`
--
ALTER TABLE `player_config`
  ADD PRIMARY KEY (`player_id`);

--
-- Indexes for table `player_immunity`
--
ALTER TABLE `player_immunity`
  ADD PRIMARY KEY (`player_id`);

--
-- Indexes for table `player_stats`
--
ALTER TABLE `player_stats`
  ADD PRIMARY KEY (`player_id`,`map_id`),
  ADD KEY `fk_map_id_idx` (`map_id`);

--
-- Indexes for table `server`
--
ALTER TABLE `server`
  ADD PRIMARY KEY (`server_id`),
  ADD UNIQUE KEY `ip_port_UNIQUE` (`ip`,`port`),
  ADD KEY `fk_server_map_idx` (`map_id`),
  ADD KEY `fk_server_server_config_idx` (`server_settings_id`);

--
-- Indexes for table `server_settings`
--
ALTER TABLE `server_settings`
  ADD PRIMARY KEY (`server_settings_id`),
  ADD KEY `fk_server_config_config_idx` (`config_start`),
  ADD KEY `fk_server_config_config_end_idx` (`config_end`);

--
-- Indexes for table `server_stats`
--
ALTER TABLE `server_stats`
  ADD PRIMARY KEY (`server_id`);

--
-- Indexes for table `tower`
--
ALTER TABLE `tower`
  ADD PRIMARY KEY (`tower_id`),
  ADD UNIQUE KEY `name_UNIQUE` (`name`);

--
-- Indexes for table `towerlevel`
--
ALTER TABLE `towerlevel`
  ADD PRIMARY KEY (`tower_id`,`level`),
  ADD KEY `fk_tower_idx` (`tower_id`),
  ADD KEY `fk_weapon_idx` (`weapon_id`);

--
-- Indexes for table `wave`
--
ALTER TABLE `wave`
  ADD PRIMARY KEY (`wave_id`);

--
-- Indexes for table `wavetype`
--
ALTER TABLE `wavetype`
  ADD PRIMARY KEY (`wavetype_id`),
  ADD UNIQUE KEY `type_UNIQUE` (`type`),
  ADD UNIQUE KEY `bitvalue_UNIQUE` (`bit_value`);

--
-- Indexes for table `weapon`
--
ALTER TABLE `weapon`
  ADD PRIMARY KEY (`weapon_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `achievement`
--
ALTER TABLE `achievement`
  MODIFY `achievement_id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `config`
--
ALTER TABLE `config`
  MODIFY `config_id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `map`
--
ALTER TABLE `map`
  MODIFY `map_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;
--
-- AUTO_INCREMENT for table `metalpack`
--
ALTER TABLE `metalpack`
  MODIFY `metalpack_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=21;
--
-- AUTO_INCREMENT for table `metalpacktype`
--
ALTER TABLE `metalpacktype`
  MODIFY `metalpacktype_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;
--
-- AUTO_INCREMENT for table `multipliertype`
--
ALTER TABLE `multipliertype`
  MODIFY `multipliertype_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;
--
-- AUTO_INCREMENT for table `player`
--
ALTER TABLE `player`
  MODIFY `player_id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `player_ban`
--
ALTER TABLE `player_ban`
  MODIFY `player_ban_id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `server`
--
ALTER TABLE `server`
  MODIFY `server_id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `server_settings`
--
ALTER TABLE `server_settings`
  MODIFY `server_settings_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;
--
-- AUTO_INCREMENT for table `tower`
--
ALTER TABLE `tower`
  MODIFY `tower_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=29;
--
-- AUTO_INCREMENT for table `wave`
--
ALTER TABLE `wave`
  MODIFY `wave_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=131;
--
-- AUTO_INCREMENT for table `wavetype`
--
ALTER TABLE `wavetype`
  MODIFY `wavetype_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;
--
-- AUTO_INCREMENT for table `weapon`
--
ALTER TABLE `weapon`
  MODIFY `weapon_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=50;
--
-- Constraints for dumped tables
--

--
-- Constraints for table `map`
--
ALTER TABLE `map`
  ADD CONSTRAINT `fk_map_wave_end` FOREIGN KEY (`wave_end`) REFERENCES `wave` (`wave_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_map_wave_start` FOREIGN KEY (`wave_start`) REFERENCES `wave` (`wave_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `metalpack`
--
ALTER TABLE `metalpack`
  ADD CONSTRAINT `fk_metalpack_map` FOREIGN KEY (`map_id`) REFERENCES `map` (`map_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_metalpack_metalpacktype` FOREIGN KEY (`metalpacktype_id`) REFERENCES `metalpacktype` (`metalpacktype_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `multiplier`
--
ALTER TABLE `multiplier`
  ADD CONSTRAINT `fk_multiplier_map` FOREIGN KEY (`map_id`) REFERENCES `map` (`map_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_multiplier_multipliertype` FOREIGN KEY (`multipliertype_id`) REFERENCES `multipliertype` (`multipliertype_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `player`
--
ALTER TABLE `player`
  ADD CONSTRAINT `fk_player_server_current` FOREIGN KEY (`current_server`) REFERENCES `server` (`server_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_player_server_first` FOREIGN KEY (`first_server`) REFERENCES `server` (`server_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_player_server_last` FOREIGN KEY (`last_server`) REFERENCES `server` (`server_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `player_achievement`
--
ALTER TABLE `player_achievement`
  ADD CONSTRAINT `fk_player_achievement_achievement` FOREIGN KEY (`achievement_id`) REFERENCES `achievement` (`achievement_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_player_achievement_player` FOREIGN KEY (`player_id`) REFERENCES `player` (`player_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `player_ban`
--
ALTER TABLE `player_ban`
  ADD CONSTRAINT `fk_player_ban_player` FOREIGN KEY (`player_id`) REFERENCES `player` (`player_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `player_config`
--
ALTER TABLE `player_config`
  ADD CONSTRAINT `fk_player_config_player` FOREIGN KEY (`player_id`) REFERENCES `player` (`player_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `player_immunity`
--
ALTER TABLE `player_immunity`
  ADD CONSTRAINT `fk_player_immunity_player` FOREIGN KEY (`player_id`) REFERENCES `player` (`player_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `player_stats`
--
ALTER TABLE `player_stats`
  ADD CONSTRAINT `fk_player_stats_map` FOREIGN KEY (`map_id`) REFERENCES `map` (`map_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_player_stats_player` FOREIGN KEY (`player_id`) REFERENCES `player` (`player_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `server`
--
ALTER TABLE `server`
  ADD CONSTRAINT `fk_server_map` FOREIGN KEY (`map_id`) REFERENCES `map` (`map_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_server_server_settings` FOREIGN KEY (`server_settings_id`) REFERENCES `server_settings` (`server_settings_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `server_settings`
--
ALTER TABLE `server_settings`
  ADD CONSTRAINT `fk_server_config_config_end` FOREIGN KEY (`config_end`) REFERENCES `config` (`config_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_server_config_config_start` FOREIGN KEY (`config_start`) REFERENCES `config` (`config_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `server_stats`
--
ALTER TABLE `server_stats`
  ADD CONSTRAINT `fk_server_stats_server` FOREIGN KEY (`server_id`) REFERENCES `server` (`server_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `towerlevel`
--
ALTER TABLE `towerlevel`
  ADD CONSTRAINT `fk_towerlevel_tower` FOREIGN KEY (`tower_id`) REFERENCES `tower` (`tower_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_towerlevel_weapon` FOREIGN KEY (`weapon_id`) REFERENCES `weapon` (`weapon_id`) ON DELETE CASCADE ON UPDATE CASCADE;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
