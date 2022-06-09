ALTER TABLE AM_API ADD API_UUID VARCHAR(255);
ALTER TABLE AM_API ADD STATUS VARCHAR(30);
ALTER TABLE AM_API ADD REVISIONS_CREATED INTEGER DEFAULT 0;
ALTER TABLE AM_CERTIFICATE_METADATA ADD CERTIFICATE BLOB DEFAULT NULL;

CREATE TABLE IF NOT EXISTS AM_REVISION (
  ID INTEGER NOT NULL,
  API_UUID VARCHAR(256) NOT NULL,
  REVISION_UUID VARCHAR(255) NOT NULL,
  DESCRIPTION VARCHAR(255),
  CREATED_TIME TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CREATED_BY VARCHAR(255),
  PRIMARY KEY (ID, API_UUID),
  UNIQUE(REVISION_UUID)
)ENGINE INNODB;


CREATE TABLE IF NOT EXISTS AM_API_REVISION_METADATA (
    API_UUID VARCHAR(64),
    REVISION_UUID VARCHAR(64),
    API_TIER VARCHAR(128),
    UNIQUE (API_UUID,REVISION_UUID)
)ENGINE INNODB;

CREATE TABLE IF NOT EXISTS AM_DEPLOYMENT_REVISION_MAPPING (
  NAME VARCHAR(255) NOT NULL,
  VHOST VARCHAR(255) NULL,
  REVISION_UUID VARCHAR(255) NOT NULL,
  DISPLAY_ON_DEVPORTAL BOOLEAN DEFAULT 0,
  DEPLOYED_TIME TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (NAME, REVISION_UUID),
  FOREIGN KEY (REVISION_UUID) REFERENCES AM_REVISION(REVISION_UUID) ON UPDATE CASCADE ON DELETE CASCADE
)ENGINE INNODB;

ALTER TABLE AM_API_CLIENT_CERTIFICATE ADD REVISION_UUID VARCHAR(255) NOT NULL DEFAULT 'Current API';
ALTER TABLE AM_API_CLIENT_CERTIFICATE DROP PRIMARY KEY;
ALTER TABLE AM_API_CLIENT_CERTIFICATE ADD PRIMARY KEY(ALIAS,TENANT_ID, REMOVED, REVISION_UUID);

ALTER TABLE AM_API_URL_MAPPING ADD REVISION_UUID VARCHAR(256);

ALTER TABLE AM_GRAPHQL_COMPLEXITY ADD REVISION_UUID VARCHAR(256);

ALTER TABLE AM_API_PRODUCT_MAPPING ADD REVISION_UUID VARCHAR(256);



DROP TABLE IF EXISTS AM_GW_API_DEPLOYMENTS;
DROP TABLE IF EXISTS AM_GW_API_ARTIFACTS;
DROP TABLE IF EXISTS AM_GW_PUBLISHED_API_DETAILS;

CREATE TABLE IF NOT EXISTS AM_GW_PUBLISHED_API_DETAILS (
  API_ID varchar(255) NOT NULL,
  TENANT_DOMAIN varchar(255),
  API_PROVIDER varchar(255),
  API_NAME varchar(255),
  API_VERSION varchar(255),
  API_TYPE varchar(50),
  PRIMARY KEY (API_ID)
)ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS AM_GW_API_ARTIFACTS (
  API_ID VARCHAR(255) NOT NULL,
  REVISION_ID VARCHAR(255) NOT NULL,
  ARTIFACT blob,
  TIME_STAMP TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (REVISION_ID, API_ID),
  FOREIGN KEY (API_ID) REFERENCES AM_GW_PUBLISHED_API_DETAILS(API_ID) ON UPDATE CASCADE ON DELETE NO ACTION
)ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS AM_GW_API_DEPLOYMENTS (
  API_ID VARCHAR(255) NOT NULL,
  REVISION_ID VARCHAR(255) NOT NULL,
  LABEL VARCHAR(255) NOT NULL,
  VHOST VARCHAR(255) NULL,
  PRIMARY KEY (REVISION_ID, API_ID,LABEL),
  FOREIGN KEY (API_ID) REFERENCES AM_GW_PUBLISHED_API_DETAILS(API_ID) ON UPDATE CASCADE ON DELETE NO ACTION
) ENGINE=InnoDB;

-- Service Catalog --
CREATE TABLE IF NOT EXISTS AM_SERVICE_CATALOG (
            UUID VARCHAR(36) NOT NULL,
            SERVICE_KEY VARCHAR(100) NOT NULL,
            MD5 VARCHAR(100) NOT NULL,
            SERVICE_NAME VARCHAR(255) NOT NULL,
            DISPLAY_NAME VARCHAR(255) NOT NULL,
            SERVICE_VERSION VARCHAR(30) NOT NULL,
            TENANT_ID INTEGER NOT NULL,
            SERVICE_URL VARCHAR(2048) NOT NULL,
            DEFINITION_TYPE VARCHAR(20),
            DEFINITION_URL VARCHAR(2048),
            DESCRIPTION VARCHAR(1024),
            SECURITY_TYPE VARCHAR(50),
            MUTUAL_SSL_ENABLED BOOLEAN DEFAULT 0,
            CREATED_TIME TIMESTAMP NULL,
            LAST_UPDATED_TIME TIMESTAMP NULL,
            CREATED_BY VARCHAR(255),
            UPDATED_BY VARCHAR(255),
            SERVICE_DEFINITION BLOB NOT NULL,
            METADATA BLOB NOT NULL,
            PRIMARY KEY (UUID),
            UNIQUE (SERVICE_NAME, SERVICE_VERSION, TENANT_ID),
            UNIQUE (SERVICE_KEY, TENANT_ID)
)ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS AM_API_SERVICE_MAPPING (
    API_ID INTEGER NOT NULL,
    SERVICE_KEY VARCHAR(256) NOT NULL,
    MD5 VARCHAR(100),
    TENANT_ID INTEGER NOT NULL,
    PRIMARY KEY (API_ID, SERVICE_KEY),
    FOREIGN KEY (API_ID) REFERENCES AM_API(API_ID) ON DELETE CASCADE
)ENGINE=InnoDB;

-- Webhooks --
CREATE TABLE IF NOT EXISTS AM_WEBHOOKS_SUBSCRIPTION (
            WH_SUBSCRIPTION_ID INTEGER NOT NULL AUTO_INCREMENT,
            API_UUID VARCHAR(255) NOT NULL,
            APPLICATION_ID VARCHAR(20) NOT NULL,
            TENANT_DOMAIN VARCHAR(255) NOT NULL,
            HUB_CALLBACK_URL VARCHAR(1024) NOT NULL,
            HUB_TOPIC VARCHAR(255) NOT NULL,
            HUB_SECRET VARCHAR(2048),
            HUB_LEASE_SECONDS INTEGER,
            UPDATED_AT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            EXPIRY_AT BIGINT,
            DELIVERED_AT TIMESTAMP NULL,
            DELIVERY_STATE TINYINT(1),
            PRIMARY KEY (WH_SUBSCRIPTION_ID)
)ENGINE INNODB;

CREATE TABLE IF NOT EXISTS AM_WEBHOOKS_UNSUBSCRIPTION (
            API_UUID VARCHAR(255) NOT NULL,
            APPLICATION_ID VARCHAR(20) NOT NULL,
            TENANT_DOMAIN VARCHAR(255) NOT NULL,
            HUB_CALLBACK_URL VARCHAR(1024) NOT NULL,
            HUB_TOPIC VARCHAR(255) NOT NULL,
            HUB_SECRET VARCHAR(2048),
            HUB_LEASE_SECONDS INTEGER,
            ADDED_AT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
)ENGINE INNODB;

-- Gateway Environments Table --
CREATE TABLE IF NOT EXISTS AM_GATEWAY_ENVIRONMENT (
  ID INTEGER NOT NULL AUTO_INCREMENT,
  UUID VARCHAR(45) NOT NULL,
  NAME VARCHAR(255) NOT NULL,
  TENANT_DOMAIN VARCHAR(255),
  DISPLAY_NAME VARCHAR(255) NULL,
  DESCRIPTION VARCHAR(1023) NULL,
  UNIQUE (NAME, TENANT_DOMAIN),
  UNIQUE (UUID),
  PRIMARY KEY (ID)
)ENGINE INNODB;

-- Virtual Hosts Table --
CREATE TABLE IF NOT EXISTS AM_GW_VHOST (
  GATEWAY_ENV_ID INTEGER,
  HOST VARCHAR(255) NOT NULL,
  HTTP_CONTEXT VARCHAR(255) NULL,
  HTTP_PORT VARCHAR(5) NOT NULL,
  HTTPS_PORT VARCHAR(5) NOT NULL,
  WS_PORT VARCHAR(5) NOT NULL,
  WSS_PORT VARCHAR(5) NOT NULL,
  FOREIGN KEY (GATEWAY_ENV_ID) REFERENCES AM_GATEWAY_ENVIRONMENT(ID) ON UPDATE CASCADE ON DELETE CASCADE,
  PRIMARY KEY (GATEWAY_ENV_ID, HOST)
)ENGINE INNODB;

ALTER TABLE AM_POLICY_SUBSCRIPTION ADD CONNECTIONS_COUNT INT(11) NOT NULL DEFAULT 0;

ALTER TABLE AM_API_COMMENTS CHANGE COMMENT_ID COMMENT_ID VARCHAR(64);
ALTER TABLE AM_API_COMMENTS CHANGE COMMENTED_USER CREATED_BY VARCHAR(512);
ALTER TABLE AM_API_COMMENTS CHANGE DATE_COMMENTED CREATED_TIME TIMESTAMP NOT NULL;
ALTER TABLE AM_API_COMMENTS ADD UPDATED_TIME TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE AM_API_COMMENTS ADD PARENT_COMMENT_ID VARCHAR(64) DEFAULT NULL;
ALTER TABLE AM_API_COMMENTS ADD ENTRY_POINT VARCHAR(20)  DEFAULT 'DEVPORTAL';
ALTER TABLE AM_API_COMMENTS ADD CATEGORY VARCHAR(20) DEFAULT 'general';
ALTER TABLE AM_API_COMMENTS ADD FOREIGN KEY(PARENT_COMMENT_ID) REFERENCES AM_API_COMMENTS(COMMENT_ID);
