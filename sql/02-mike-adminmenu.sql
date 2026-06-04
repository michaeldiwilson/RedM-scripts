CREATE TABLE IF NOT EXISTS `mike_bans` (
    `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `license`    VARCHAR(100) DEFAULT NULL,
    `steam`      VARCHAR(100) DEFAULT NULL,
    `discord`    VARCHAR(100) DEFAULT NULL,
    `xbl`        VARCHAR(100) DEFAULT NULL,
    `ip`         VARCHAR(64)  DEFAULT NULL,
    `name`       VARCHAR(120) DEFAULT NULL,
    `reason`     TEXT,
    `banned_by`  VARCHAR(120) DEFAULT NULL,
    `created_at` BIGINT       NOT NULL,
    `expires_at` BIGINT       DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_license` (`license`),
    KEY `idx_steam`   (`steam`),
    KEY `idx_discord` (`discord`),
    KEY `idx_expires` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
