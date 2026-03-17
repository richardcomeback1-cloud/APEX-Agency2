-- APEX-BossAction required SQL
-- สร้าง shared account สำหรับหน่วยงานที่ใช้ใน Config.Position

CREATE TABLE IF NOT EXISTS `addon_account` (
  `name` varchar(60) NOT NULL,
  `label` varchar(100) NOT NULL,
  `shared` int(11) NOT NULL,
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `addon_account_data` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `account_name` varchar(100) DEFAULT NULL,
  `money` int(11) NOT NULL,
  `owner` varchar(60) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `account_name_owner` (`account_name`,`owner`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO `addon_account` (`name`, `label`, `shared`) VALUES
('society_ambulance', 'Ambulance', 1),
('society_police', 'Police', 1),
('society_council', 'Council', 1);

INSERT IGNORE INTO `addon_account_data` (`account_name`, `money`, `owner`) VALUES
('society_ambulance', 0, NULL),
('society_police', 0, NULL),
('society_council', 0, NULL);
