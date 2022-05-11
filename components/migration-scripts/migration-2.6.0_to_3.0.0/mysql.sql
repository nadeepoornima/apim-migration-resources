CREATE TABLE IF NOT EXISTS AM_SYSTEM_APPS (
    ID INTEGER AUTO_INCREMENT,
    NAME VARCHAR(50) NOT NULL,
    CONSUMER_KEY VARCHAR(512) NOT NULL,
    CONSUMER_SECRET VARCHAR(512) NOT NULL,
    CREATED_TIME TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (NAME),
    UNIQUE (CONSUMER_KEY),
    PRIMARY KEY (ID)
 ) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS AM_API_CLIENT_CERTIFICATE (
  TENANT_ID INT(11) NOT NULL,
  ALIAS VARCHAR(45) NOT NULL,
  API_ID INTEGER NOT NULL,
  CERTIFICATE BLOB NOT NULL,
  REMOVED BOOLEAN NOT NULL DEFAULT 0,
  TIER_NAME VARCHAR (512),
  FOREIGN KEY (API_ID) REFERENCES AM_API (API_ID) ON DELETE CASCADE ON UPDATE CASCADE,
  PRIMARY KEY (ALIAS,TENANT_ID, REMOVED)
);

ALTER TABLE AM_POLICY_SUBSCRIPTION 
  ADD MONETIZATION_PLAN VARCHAR(25) NULL DEFAULT NULL, 
  ADD FIXED_RATE VARCHAR(15) NULL DEFAULT NULL, 
  ADD BILLING_CYCLE VARCHAR(15) NULL DEFAULT NULL, 
  ADD PRICE_PER_REQUEST VARCHAR(15) NULL DEFAULT NULL, 
  ADD CURRENCY VARCHAR(15) NULL DEFAULT NULL;

CREATE TABLE IF NOT EXISTS AM_MONETIZATION_USAGE_PUBLISHER (
	ID VARCHAR(100) NOT NULL,
	STATE VARCHAR(50) NOT NULL,
	STATUS VARCHAR(50) NOT NULL,
	STARTED_TIME VARCHAR(50) NOT NULL,
	PUBLISHED_TIME VARCHAR(50) NOT NULL,
	PRIMARY KEY(ID)
) ENGINE INNODB;

ALTER TABLE AM_API_COMMENTS
MODIFY COLUMN COMMENT_ID VARCHAR(255) NOT NULL;

ALTER TABLE AM_API_RATINGS
MODIFY COLUMN RATING_ID VARCHAR(255) NOT NULL;

CREATE TABLE IF NOT EXISTS AM_NOTIFICATION_SUBSCRIBER (
    UUID VARCHAR(255),
    CATEGORY VARCHAR(255),
    NOTIFICATION_METHOD VARCHAR(255),
    SUBSCRIBER_ADDRESS VARCHAR(255) NOT NULL,
    PRIMARY KEY(UUID, SUBSCRIBER_ADDRESS)
) ENGINE INNODB;

ALTER TABLE AM_EXTERNAL_STORES
ADD LAST_UPDATED_TIME TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE AM_API
  ADD API_TYPE VARCHAR(10) NULL DEFAULT NULL;

CREATE TABLE IF NOT EXISTS AM_API_PRODUCT_MAPPING (
  API_PRODUCT_MAPPING_ID INTEGER AUTO_INCREMENT,
  API_ID INTEGER,
  URL_MAPPING_ID INTEGER,
  FOREIGN KEY (API_ID) REFERENCES AM_API(API_ID) ON DELETE CASCADE,
  FOREIGN KEY (URL_MAPPING_ID) REFERENCES AM_API_URL_MAPPING(URL_MAPPING_ID) ON DELETE CASCADE,
  PRIMARY KEY(API_PRODUCT_MAPPING_ID)
)ENGINE INNODB;

CREATE TABLE IF NOT EXISTS AM_REVOKED_JWT (
    UUID VARCHAR(255) NOT NULL,
    SIGNATURE VARCHAR(2048) NOT NULL,
    EXPIRY_TIMESTAMP BIGINT NOT NULL,
    TENANT_ID INTEGER DEFAULT -1,
    TOKEN_TYPE VARCHAR(15) DEFAULT 'DEFAULT',
    TIME_CREATED TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (UUID)
) ENGINE=InnoDB;

ALTER TABLE AM_API ADD API_UUID VARCHAR(255);
