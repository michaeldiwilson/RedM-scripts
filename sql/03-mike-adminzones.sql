CREATE TABLE IF NOT EXISTS `mike_admin_zones` (
    `id`           INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name`         VARCHAR(100) NOT NULL,
    `x`            FLOAT NOT NULL,
    `y`            FLOAT NOT NULL,
    `z`            FLOAT NOT NULL,
    `radius`       FLOAT NOT NULL DEFAULT 20.0,
    `blip_sprite`  INT DEFAULT NULL,
    `blip_color`   INT DEFAULT 0,
    `auto_revive`  TINYINT(1) NOT NULL DEFAULT 0,
    `disarm`       TINYINT(1) NOT NULL DEFAULT 0,
    `invincible`   TINYINT(1) NOT NULL DEFAULT 0,
    `speed_limit`  FLOAT DEFAULT NULL,
    `created_by`   VARCHAR(120) DEFAULT NULL,
    `created_at`   BIGINT NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
