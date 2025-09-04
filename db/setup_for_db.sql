CREATE USER IF NOT EXISTS tubescope_user IDENTIFIED BY 'tubescope';


CREATE DATABASE IF NOT EXISTS tubescope_dev DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;

GRANT ALL PRIVILEGES on tubescope_dev.* to tubescope_user;


CREATE DATABASE IF NOT EXISTS tubescope_test DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;

GRANT ALL PRIVILEGES on tubescope_test.* to tubescope_user;
