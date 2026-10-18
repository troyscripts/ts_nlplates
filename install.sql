-- Troy Scripts - ts_nlplates 1.0.3
-- Importeer in dezelfde database als ESX / owned_vehicles.
-- Deze installatie verwijdert niets en hernummert geen bestaande voertuigen.
-- Het ox_inventory-item wordt in data/items.lua gedefinieerd, niet in SQL.

CREATE TABLE IF NOT EXISTS ts_nlplates_numbers (
    plate VARCHAR(8) NOT NULL PRIMARY KEY,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS ts_nlplates_documents (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    plate VARCHAR(8) NOT NULL UNIQUE,
    model VARCHAR(32) NOT NULL,
    issued TINYINT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
