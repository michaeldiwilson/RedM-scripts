CREATE TABLE IF NOT EXISTS `mike_stills` (
    `id`             INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `owner_cid`      VARCHAR(60)  NOT NULL,
    `x`              FLOAT NOT NULL,
    `y`              FLOAT NOT NULL,
    `z`              FLOAT NOT NULL,
    `heading`        FLOAT NOT NULL DEFAULT 0,
    `state`          VARCHAR(20)  NOT NULL DEFAULT 'empty',
    `stage_started`  BIGINT DEFAULT NULL,
    `mash_batches`   INT NOT NULL DEFAULT 0,
    `quality_score`  INT NOT NULL DEFAULT 0,
    `bottles_ready`  INT NOT NULL DEFAULT 0,
    `bottle_tier`    VARCHAR(20) DEFAULT NULL,
    `created_at`     BIGINT NOT NULL,
    `destroyed`      TINYINT(1) NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    KEY `idx_owner` (`owner_cid`),
    KEY `idx_coords` (`x`, `y`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
