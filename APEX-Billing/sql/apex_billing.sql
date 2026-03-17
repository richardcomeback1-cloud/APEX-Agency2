CREATE TABLE IF NOT EXISTS `apex_bills` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `identifier` VARCHAR(64) NOT NULL,
  `amount` INT NOT NULL,
  `reason` VARCHAR(128) NOT NULL,
  `pay` TINYINT(1) NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `pay_time` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_apex_bills_identifier_pay` (`identifier`, `pay`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
