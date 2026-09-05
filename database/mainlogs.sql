-- MySqlBackup.NET 2.3.4
-- Dump Time: 2026-09-04 11:01:07
-- --------------------------------------
-- Server version 10.5.19-MariaDB mariadb.org binary distribution


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;


-- 
-- Definition of acclog
-- 

DROP TABLE IF EXISTS `acclog`;
CREATE TABLE IF NOT EXISTS `acclog` (
  `time` datetime NOT NULL,
  `login` varchar(50) NOT NULL,
  `hwid` varchar(256) NOT NULL,
  `ip` varchar(256) NOT NULL,
  `sclub` varchar(50) NOT NULL,
  `action` varchar(100) NOT NULL,
  KEY `time` (`time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC;

-- 
-- Dumping data for table acclog
-- 

/*!40000 ALTER TABLE `acclog` DISABLE KEYS */;

/*!40000 ALTER TABLE `acclog` ENABLE KEYS */;

-- 
-- Definition of addinfo
-- 

DROP TABLE IF EXISTS `addinfo`;
CREATE TABLE IF NOT EXISTS `addinfo` (
  `time` datetime NOT NULL,
  `action` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- 
-- Dumping data for table addinfo
-- 

/*!40000 ALTER TABLE `addinfo` DISABLE KEYS */;

/*!40000 ALTER TABLE `addinfo` ENABLE KEYS */;

-- 
-- Definition of adminlog
-- 

DROP TABLE IF EXISTS `adminlog`;
CREATE TABLE IF NOT EXISTS `adminlog` (
  `time` datetime NOT NULL,
  `admin` varchar(50) NOT NULL,
  `action` varchar(350) NOT NULL,
  `player` varchar(50) NOT NULL,
  KEY `time` (`time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC;

-- 
-- Dumping data for table adminlog
-- 

/*!40000 ALTER TABLE `adminlog` DISABLE KEYS */;

/*!40000 ALTER TABLE `adminlog` ENABLE KEYS */;

-- 
-- Definition of arrestlog
-- 

DROP TABLE IF EXISTS `arrestlog`;
CREATE TABLE IF NOT EXISTS `arrestlog` (
  `time` datetime DEFAULT NULL,
  `player` int(11) DEFAULT NULL,
  `target` int(11) DEFAULT NULL,
  `reason` varchar(300) DEFAULT NULL,
  `stars` int(11) DEFAULT NULL,
  `pnick` varchar(60) DEFAULT NULL,
  `tnick` varchar(60) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- 
-- Dumping data for table arrestlog
-- 

/*!40000 ALTER TABLE `arrestlog` DISABLE KEYS */;

/*!40000 ALTER TABLE `arrestlog` ENABLE KEYS */;

-- 
-- Definition of banlog
-- 

DROP TABLE IF EXISTS `banlog`;
CREATE TABLE IF NOT EXISTS `banlog` (
  `time` datetime NOT NULL,
  `admin` int(11) NOT NULL,
  `player` int(11) NOT NULL,
  `login` varchar(50) DEFAULT NULL,
  `until` datetime NOT NULL,
  `reason` varchar(300) NOT NULL,
  `ishard` tinyint(4) NOT NULL,
  `rgscemailhash` varchar(128) DEFAULT '-',
  KEY `time` (`time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- 
-- Dumping data for table banlog
-- 

/*!40000 ALTER TABLE `banlog` DISABLE KEYS */;

/*!40000 ALTER TABLE `banlog` ENABLE KEYS */;

-- 
-- Definition of casinolog
-- 

DROP TABLE IF EXISTS `casinolog`;
CREATE TABLE IF NOT EXISTS `casinolog` (
  `roulette` bigint(20) DEFAULT 0,
  `horses` bigint(20) DEFAULT 0,
  `spins` bigint(20) DEFAULT 0,
  `bj` bigint(20) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- 
-- Dumping data for table casinolog
-- 

/*!40000 ALTER TABLE `casinolog` DISABLE KEYS */;

/*!40000 ALTER TABLE `casinolog` ENABLE KEYS */;

-- 
-- Definition of client_tc
-- 

DROP TABLE IF EXISTS `client_tc`;
CREATE TABLE IF NOT EXISTS `client_tc` (
  `time` datetime DEFAULT NULL,
  `path` varchar(50) DEFAULT NULL,
  `callback` varchar(100) DEFAULT NULL,
  `message` varchar(1000) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- 
-- Dumping data for table client_tc
-- 

/*!40000 ALTER TABLE `client_tc` DISABLE KEYS */;

/*!40000 ALTER TABLE `client_tc` ENABLE KEYS */;

-- 
-- Definition of deletelog
-- 

DROP TABLE IF EXISTS `deletelog`;
CREATE TABLE IF NOT EXISTS `deletelog` (
  `time` datetime DEFAULT NULL,
  `uuid` int(11) DEFAULT NULL,
  `name` varchar(100) DEFAULT NULL,
  `account` varchar(50) DEFAULT NULL,
  `bank` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- 
-- Dumping data for table deletelog
-- 

/*!40000 ALTER TABLE `deletelog` DISABLE KEYS */;

/*!40000 ALTER TABLE `deletelog` ENABLE KEYS */;

-- 
-- Definition of events
-- 

DROP TABLE IF EXISTS `events`;
CREATE TABLE IF NOT EXISTS `events` (
  `ID` int(11) DEFAULT NULL,
  `Event` text DEFAULT NULL,
  `Calls` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- 
-- Dumping data for table events
-- 

/*!40000 ALTER TABLE `events` DISABLE KEYS */;

/*!40000 ALTER TABLE `events` ENABLE KEYS */;

-- 
-- Definition of eventslog
-- 

DROP TABLE IF EXISTS `eventslog`;
CREATE TABLE IF NOT EXISTS `eventslog` (
  `ID` int(12) NOT NULL AUTO_INCREMENT,
  `AdminStarted` varchar(40) NOT NULL,
  `AdminClosed` varchar(40) DEFAULT NULL,
  `EventName` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `Members` smallint(4) unsigned NOT NULL DEFAULT 0,
  `MembersLimit` smallint(4) unsigned NOT NULL,
  `Winner` varchar(40) NOT NULL DEFAULT 'Undefined',
  `Reward` int(6) NOT NULL DEFAULT 0,
  `RewardLimit` int(6) unsigned NOT NULL DEFAULT 0,
  `Started` datetime NOT NULL,
  `Ended` datetime DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB AUTO_INCREMENT=854 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- 
-- Dumping data for table eventslog
-- 

/*!40000 ALTER TABLE `eventslog` DISABLE KEYS */;

/*!40000 ALTER TABLE `eventslog` ENABLE KEYS */;

-- 
-- Definition of fraclog
-- 

DROP TABLE IF EXISTS `fraclog`;
CREATE TABLE IF NOT EXISTS `fraclog` (
  `time` datetime DEFAULT NULL,
  `frac` varchar(25) DEFAULT NULL,
  `player` int(11) DEFAULT NULL,
  `target` int(11) DEFAULT NULL,
  `pname` varchar(50) DEFAULT NULL,
  `tname` varchar(50) DEFAULT NULL,
  `action` varchar(350) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- 
-- Dumping data for table fraclog
-- 

/*!40000 ALTER TABLE `fraclog` DISABLE KEYS */;

/*!40000 ALTER TABLE `fraclog` ENABLE KEYS */;

-- 
-- Definition of idlog
-- 

DROP TABLE IF EXISTS `idlog`;
CREATE TABLE IF NOT EXISTS `idlog` (
  `in` datetime NOT NULL,
  `out` datetime DEFAULT NULL,
  `uuid` int(11) NOT NULL,
  `id` int(11) NOT NULL,
  `name` varchar(50) DEFAULT NULL,
  `sclub` varchar(50) DEFAULT NULL,
  `hwid` varchar(256) DEFAULT NULL,
  `ip` varchar(30) DEFAULT NULL,
  `login` varchar(50) DEFAULT NULL,
  `reason` varchar(50) DEFAULT NULL,
  KEY `in` (`in`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC;

-- 
-- Dumping data for table idlog
-- 

/*!40000 ALTER TABLE `idlog` DISABLE KEYS */;

/*!40000 ALTER TABLE `idlog` ENABLE KEYS */;

-- 
-- Definition of itemslog
-- 

DROP TABLE IF EXISTS `itemslog`;
CREATE TABLE IF NOT EXISTS `itemslog` (
  `time` datetime NOT NULL,
  `from` varchar(50) NOT NULL,
  `to` varchar(50) NOT NULL,
  `type` int(4) NOT NULL,
  `amount` int(11) NOT NULL,
  `data` varchar(250) NOT NULL,
  KEY `time` (`time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC;

-- 
-- Dumping data for table itemslog
-- 

/*!40000 ALTER TABLE `itemslog` DISABLE KEYS */;
INSERT INTO `itemslog`(`time`,`from`,`to`,`type`,`amount`,`data`) VALUES
('2026-09-03 14:17:09','newItem(4)','helicrash_2',110,1,'HELI100001'),
('2026-09-03 14:17:09','newItem(10)','helicrash_1',1,1,''),
('2026-09-03 14:17:09','newItem(6)','helicrash_1',1,1,''),
('2026-09-03 14:17:09','newItem(5)','helicrash_3',2,2,''),
('2026-09-03 14:17:09','newItem(3)','helicrash_2',-1,1,'38_0_True'),
('2026-09-03 14:17:09','newItem(12)','helicrash_3',2,2,''),
('2026-09-03 14:17:09','newItem(11)','helicrash_2',-1,1,'177_0_True'),
('2026-09-03 14:17:09','newItem(8)','helicrash_2',-1,1,'46_0_True'),
('2026-09-03 14:17:09','newItem(2)','helicrash_1',1,1,''),
('2026-09-03 14:17:09','newItem(9)','helicrash_2',-1,1,'186_0_True'),
('2026-09-03 14:17:09','newItem(1)','helicrash_1',1,1,''),
('2026-09-03 14:17:09','newItem(7)','helicrash_1',1,1,''),
('2026-09-03 14:17:09','newItem(13)','helicrash_1',1,1,'');
/*!40000 ALTER TABLE `itemslog` ENABLE KEYS */;

-- 
-- Definition of killlog
-- 

DROP TABLE IF EXISTS `killlog`;
CREATE TABLE IF NOT EXISTS `killlog` (
  `time` datetime DEFAULT NULL,
  `killer` varchar(50) DEFAULT NULL,
  `weapon` varchar(50) DEFAULT NULL,
  `victim` varchar(50) DEFAULT NULL,
  `pos` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- 
-- Dumping data for table killlog
-- 

/*!40000 ALTER TABLE `killlog` DISABLE KEYS */;

/*!40000 ALTER TABLE `killlog` ENABLE KEYS */;

-- 
-- Definition of moneylog
-- 

DROP TABLE IF EXISTS `moneylog`;
CREATE TABLE IF NOT EXISTS `moneylog` (
  `time` datetime NOT NULL,
  `from` varchar(50) NOT NULL,
  `to` varchar(50) NOT NULL,
  `amount` bigint(20) NOT NULL,
  `comment` varchar(50) NOT NULL,
  KEY `time` (`time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- 
-- Dumping data for table moneylog
-- 

/*!40000 ALTER TABLE `moneylog` DISABLE KEYS */;

/*!40000 ALTER TABLE `moneylog` ENABLE KEYS */;

-- 
-- Definition of namelog
-- 

DROP TABLE IF EXISTS `namelog`;
CREATE TABLE IF NOT EXISTS `namelog` (
  `time` datetime NOT NULL,
  `uuid` int(11) NOT NULL,
  `old` varchar(50) NOT NULL,
  `new` varchar(50) NOT NULL,
  KEY `time` (`time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- 
-- Dumping data for table namelog
-- 

/*!40000 ALTER TABLE `namelog` DISABLE KEYS */;

/*!40000 ALTER TABLE `namelog` ENABLE KEYS */;

-- 
-- Definition of stocklog
-- 

DROP TABLE IF EXISTS `stocklog`;
CREATE TABLE IF NOT EXISTS `stocklog` (
  `time` datetime NOT NULL,
  `frac` int(5) NOT NULL,
  `uuid` int(8) NOT NULL,
  `name` varchar(50) NOT NULL DEFAULT '-1',
  `type` varchar(35) NOT NULL,
  `amount` int(11) NOT NULL,
  `in` tinyint(2) NOT NULL,
  KEY `time` (`time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC;

-- 
-- Dumping data for table stocklog
-- 

/*!40000 ALTER TABLE `stocklog` DISABLE KEYS */;

/*!40000 ALTER TABLE `stocklog` ENABLE KEYS */;

-- 
-- Definition of ticketlog
-- 

DROP TABLE IF EXISTS `ticketlog`;
CREATE TABLE IF NOT EXISTS `ticketlog` (
  `time` datetime DEFAULT NULL,
  `player` int(11) DEFAULT NULL,
  `target` int(11) DEFAULT NULL,
  `sum` int(11) DEFAULT NULL,
  `reason` varchar(300) DEFAULT NULL,
  `pnick` varchar(60) DEFAULT NULL,
  `tnick` varchar(60) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- 
-- Dumping data for table ticketlog
-- 

/*!40000 ALTER TABLE `ticketlog` DISABLE KEYS */;

/*!40000 ALTER TABLE `ticketlog` ENABLE KEYS */;

-- 
-- Definition of unique
-- 

DROP TABLE IF EXISTS `unique`;
CREATE TABLE IF NOT EXISTS `unique` (
  `time` datetime DEFAULT NULL,
  `count` int(11) DEFAULT NULL,
  `maxplayers` int(11) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- 
-- Dumping data for table unique
-- 

/*!40000 ALTER TABLE `unique` DISABLE KEYS */;

/*!40000 ALTER TABLE `unique` ENABLE KEYS */;

-- 
-- Dumping procedures
-- 

DROP PROCEDURE IF EXISTS `addLogsData`;
DELIMITER |
CREATE PROCEDURE `addLogsData`(
	IN `in_table` VARCHAR(32),
	IN `in_where` VARCHAR(500),
	IN `in_what` VARCHAR(1000)
)
    COMMENT 'Добавление данных в логи'
BEGIN
	SET @s = CONCAT('INSERT INTO ', in_table, ' (', in_where, ') VALUES (', in_what,')');
	PREPARE stm FROM @s;
	EXECUTE stm;
END |
DELIMITER ;

DROP PROCEDURE IF EXISTS `updLogsData`;
DELIMITER |
CREATE PROCEDURE `updLogsData`(
	IN `in_table` VARCHAR(32),
	IN `in_datas` VARCHAR(1000),
	IN `in_where` VARCHAR(500)
)
    COMMENT 'Обновление данных в логах'
BEGIN
    SET @s = CONCAT('UPDATE ', in_table, ' SET ', in_datas, ' WHERE ', in_where);
    PREPARE stm FROM @s;
    EXECUTE stm;
END |
DELIMITER ;


/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;


-- Dump completed on 2026-09-04 11:01:07
-- Total time: 0:0:0:0:212 (d:h:m:s:ms)
