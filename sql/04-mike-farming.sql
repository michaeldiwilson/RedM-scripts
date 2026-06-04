CREATE TABLE IF NOT EXISTS `mike_crops` (
    `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `owner_cid`     VARCHAR(60) NOT NULL,
    `crop_type`     VARCHAR(40) NOT NULL,
    `x`             FLOAT NOT NULL,
    `y`             FLOAT NOT NULL,
    `z`             FLOAT NOT NULL,
    `planted_at`    BIGINT NOT NULL,
    `last_watered`  BIGINT NOT NULL,
    `fertilized`    TINYINT(1) NOT NULL DEFAULT 0,
    `withered`      TINYINT(1) NOT NULL DEFAULT 0,
    `harvested`     TINYINT(1) NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    KEY `idx_owner` (`owner_cid`),
    KEY `idx_location` (`x`, `y`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
