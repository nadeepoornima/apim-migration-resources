ALTER TABLE AM_API ADD API_UUID VARCHAR(255);
ALTER TABLE AM_API ADD STATUS VARCHAR(30);
ALTER TABLE AM_CERTIFICATE_METADATA ADD CERTIFICATE VARBINARY(MAX) DEFAULT NULL;
ALTER TABLE AM_API ADD REVISIONS_CREATED INTEGER DEFAULT 0;

IF NOT EXISTS (SELECT * FROM SYS.OBJECTS WHERE OBJECT_ID = OBJECT_ID(N'[DBO].[AM_REVISION]') AND TYPE IN (N'U'))
CREATE TABLE AM_REVISION (
  ID INTEGER NOT NULL,
  API_UUID VARCHAR(256) NOT NULL,
  REVISION_UUID VARCHAR(255) NOT NULL,
  DESCRIPTION VARCHAR(255),
  CREATED_TIME DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CREATED_BY VARCHAR(255),
  PRIMARY KEY (ID, API_UUID),
  UNIQUE(REVISION_UUID)
);

IF NOT  EXISTS (SELECT * FROM SYS.OBJECTS WHERE OBJECT_ID = OBJECT_ID(N'[DBO].[AM_API_REVISION_METADATA]') AND TYPE IN (N'U'))

CREATE TABLE AM_API_REVISION_METADATA (
    API_UUID VARCHAR(64),
    REVISION_UUID VARCHAR(64),
    API_TIER VARCHAR(128),
    UNIQUE (API_UUID,REVISION_UUID)
);

IF NOT EXISTS (SELECT * FROM SYS.OBJECTS WHERE OBJECT_ID = OBJECT_ID(N'[DBO].[AM_DEPLOYMENT_REVISION_MAPPING]') AND TYPE IN (N'U'))
CREATE TABLE AM_DEPLOYMENT_REVISION_MAPPING (
  NAME VARCHAR(255) NOT NULL,
  VHOST VARCHAR(255) NULL,
  REVISION_UUID VARCHAR(255) NOT NULL,
  DISPLAY_ON_DEVPORTAL BIT DEFAULT 0,
  DEPLOYED_TIME DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (NAME, REVISION_UUID),
  FOREIGN KEY (REVISION_UUID) REFERENCES AM_REVISION(REVISION_UUID) ON UPDATE CASCADE ON DELETE CASCADE
);

DECLARE @con_com as VARCHAR(8000);
SET @con_com = (SELECT name from sys.objects where parent_object_id=object_id('AM_API_CLIENT_CERTIFICATE') AND type='PK');
EXEC('ALTER TABLE AM_API_CLIENT_CERTIFICATE
drop CONSTRAINT ' + @con_com);
ALTER TABLE AM_API_CLIENT_CERTIFICATE ADD REVISION_UUID VARCHAR(255) NOT NULL DEFAULT 'Current API';
ALTER TABLE AM_API_CLIENT_CERTIFICATE ADD PRIMARY KEY(ALIAS,TENANT_ID, REMOVED, REVISION_UUID);

ALTER TABLE AM_API_URL_MAPPING ADD REVISION_UUID VARCHAR(256);

ALTER TABLE AM_GRAPHQL_COMPLEXITY ADD REVISION_UUID VARCHAR(256);

ALTER TABLE AM_API_PRODUCT_MAPPING ADD REVISION_UUID VARCHAR(256);

DROP TABLE IF EXISTS AM_GW_API_DEPLOYMENTS;
DROP TABLE IF EXISTS AM_GW_API_ARTIFACTS;
DROP TABLE IF EXISTS AM_GW_PUBLISHED_API_DETAILS;

IF NOT  EXISTS (SELECT * FROM SYS.OBJECTS WHERE OBJECT_ID = OBJECT_ID(N'[DBO].[AM_GW_PUBLISHED_API_DETAILS]') AND TYPE IN (N'U'))
CREATE TABLE AM_GW_PUBLISHED_API_DETAILS (
  API_ID varchar(255) NOT NULL,
  TENANT_DOMAIN varchar(255),
  API_PROVIDER varchar(255),
  API_NAME varchar(255),
  API_VERSION varchar(255),
  API_TYPE varchar(50),
  PRIMARY KEY (API_ID)
);

IF NOT  EXISTS (SELECT * FROM SYS.OBJECTS WHERE OBJECT_ID = OBJECT_ID(N'[DBO].[AM_GW_API_ARTIFACTS]') AND TYPE IN (N'U'))
CREATE TABLE  AM_GW_API_ARTIFACTS (
  API_ID varchar(255) NOT NULL,
  REVISION_ID varchar(255) NOT NULL,
  ARTIFACT VARBINARY(MAX),
  TIME_STAMP DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (REVISION_ID, API_ID),
  FOREIGN KEY (API_ID) REFERENCES AM_GW_PUBLISHED_API_DETAILS(API_ID) ON UPDATE CASCADE ON DELETE NO ACTION
);

IF NOT  EXISTS (SELECT * FROM SYS.OBJECTS WHERE OBJECT_ID = OBJECT_ID(N'[DBO].[AM_GW_API_DEPLOYMENTS]') AND TYPE IN (N'U'))
CREATE TABLE AM_GW_API_DEPLOYMENTS (
  API_ID VARCHAR(255) NOT NULL,
  REVISION_ID VARCHAR(255) NOT NULL,
  LABEL VARCHAR(255) NOT NULL,
  VHOST VARCHAR(255) NULL,
  PRIMARY KEY (REVISION_ID, API_ID,LABEL),
  FOREIGN KEY (API_ID) REFERENCES AM_GW_PUBLISHED_API_DETAILS(API_ID) ON UPDATE CASCADE ON DELETE NO ACTION
) ;

-- Service Catalog Tables --
IF NOT  EXISTS (SELECT * FROM SYS.OBJECTS WHERE OBJECT_ID = OBJECT_ID(N'[DBO].[AM_SERVICE_CATALOG]') AND TYPE IN (N'U'))
CREATE TABLE AM_SERVICE_CATALOG (
  UUID VARCHAR(36) NOT NULL,
  SERVICE_KEY VARCHAR(100) NOT NULL,
  MD5 VARCHAR(100) NOT NULL,
  SERVICE_NAME VARCHAR(255) NOT NULL,
  DISPLAY_NAME VARCHAR(255) NOT NULL,
  SERVICE_VERSION VARCHAR(30) NOT NULL,
  SERVICE_URL VARCHAR(2048) NOT NULL,
  TENANT_ID INTEGER NOT NULL,
  DEFINITION_TYPE VARCHAR(20),
  DEFINITION_URL VARCHAR(2048),
  DESCRIPTION VARCHAR(1024),
  SECURITY_TYPE VARCHAR(50),
  MUTUAL_SSL_ENABLED BIT DEFAULT 0,
  CREATED_TIME DATETIME NULL,
  LAST_UPDATED_TIME DATETIME NULL,
  CREATED_BY VARCHAR(255),
  UPDATED_BY VARCHAR(255),
  SERVICE_DEFINITION VARBINARY(MAX) NOT NULL,
  METADATA VARBINARY(MAX) NOT NULL,
  PRIMARY KEY (UUID),
  CONSTRAINT SERVICE_KEY_TENANT UNIQUE(SERVICE_KEY, TENANT_ID),
  CONSTRAINT SERVICE_NAME_VERSION_TENANT UNIQUE (SERVICE_NAME, SERVICE_VERSION, TENANT_ID)
);

-- Webhooks --
IF NOT  EXISTS (SELECT * FROM SYS.OBJECTS WHERE OBJECT_ID = OBJECT_ID(N'[DBO].[AM_WEBHOOKS_SUBSCRIPTION]') AND TYPE IN (N'U'))
CREATE TABLE AM_WEBHOOKS_SUBSCRIPTION (
    WH_SUBSCRIPTION_ID INTEGER IDENTITY,
    API_UUID VARCHAR(255) NOT NULL,
    APPLICATION_ID VARCHAR(20) NOT NULL,
    TENANT_DOMAIN VARCHAR(255) NOT NULL,
    HUB_CALLBACK_URL VARCHAR(1024) NOT NULL,
    HUB_TOPIC VARCHAR(255) NOT NULL,
    HUB_SECRET VARCHAR(2048),
    HUB_LEASE_SECONDS INTEGER,
    UPDATED_AT DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    EXPIRY_AT BIGINT,
    DELIVERED_AT DATETIME NULL,
    DELIVERY_STATE INTEGER,
    PRIMARY KEY (WH_SUBSCRIPTION_ID)
);

IF NOT  EXISTS (SELECT * FROM SYS.OBJECTS WHERE OBJECT_ID = OBJECT_ID(N'[DBO].[AM_WEBHOOKS_UNSUBSCRIPTION]') AND TYPE IN (N'U'))
CREATE TABLE AM_WEBHOOKS_UNSUBSCRIPTION (
    API_UUID VARCHAR(255) NOT NULL,
    APPLICATION_ID VARCHAR(20) NOT NULL,
    TENANT_DOMAIN VARCHAR(255) NOT NULL,
    HUB_CALLBACK_URL VARCHAR(1024) NOT NULL,
    HUB_TOPIC VARCHAR(255) NOT NULL,
    HUB_SECRET VARCHAR(2048),
    HUB_LEASE_SECONDS INTEGER,
    ADDED_AT DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
IF NOT  EXISTS (SELECT * FROM SYS.OBJECTS WHERE OBJECT_ID = OBJECT_ID(N'[DBO].[AM_API_SERVICE_MAPPING]') AND TYPE IN (N'U'))
CREATE TABLE AM_API_SERVICE_MAPPING (
    API_ID INTEGER NOT NULL,
    SERVICE_KEY VARCHAR(256) NOT NULL,
    MD5 VARCHAR(100) NOT NULL,
    TENANT_ID INTEGER NOT NULL,
    PRIMARY KEY (API_ID, SERVICE_KEY),
    FOREIGN KEY (API_ID) REFERENCES AM_API(API_ID) ON DELETE CASCADE
);

-- Gateway Environments Table --
IF NOT EXISTS (SELECT * FROM SYS.OBJECTS WHERE OBJECT_ID = OBJECT_ID(N'[DBO].[AM_GATEWAY_ENVIRONMENT]') AND TYPE IN (N'U'))
CREATE TABLE AM_GATEWAY_ENVIRONMENT (
  ID INTEGER IDENTITY,
  UUID VARCHAR(45) NOT NULL,
  NAME VARCHAR(255) NOT NULL,
  TENANT_DOMAIN VARCHAR(255),
  DISPLAY_NAME VARCHAR(255) NULL,
  DESCRIPTION VARCHAR(1023) NULL,
  UNIQUE (NAME, TENANT_DOMAIN),
  UNIQUE (UUID),
  PRIMARY KEY (ID)
);

-- Virtual Hosts Table --
IF NOT EXISTS (SELECT * FROM SYS.OBJECTS WHERE OBJECT_ID = OBJECT_ID(N'[DBO].[AM_GW_VHOST]') AND TYPE IN (N'U'))
CREATE TABLE AM_GW_VHOST (
  GATEWAY_ENV_ID INTEGER,
  HOST VARCHAR(255) NOT NULL,
  HTTP_CONTEXT VARCHAR(255) NULL,
  HTTP_PORT VARCHAR(5) NOT NULL,
  HTTPS_PORT VARCHAR(5) NOT NULL,
  WS_PORT VARCHAR(5) NOT NULL,
  WSS_PORT VARCHAR(5) NOT NULL,
  FOREIGN KEY (GATEWAY_ENV_ID) REFERENCES AM_GATEWAY_ENVIRONMENT(ID) ON UPDATE CASCADE ON DELETE CASCADE,
  PRIMARY KEY (GATEWAY_ENV_ID, HOST)
);

ALTER TABLE AM_POLICY_SUBSCRIPTION ADD CONNECTIONS_COUNT INTEGER NOT NULL DEFAULT 0;

EXEC sp_rename 'AM_API_COMMENTS.COMMENTED_USER', 'CREATED_BY', 'COLUMN';
EXEC sp_rename 'AM_API_COMMENTS.DATE_COMMENTED', 'CREATED_TIME', 'COLUMN';
ALTER TABLE AM_API_COMMENTS ADD UPDATED_TIME DATETIME;
ALTER TABLE AM_API_COMMENTS ADD PARENT_COMMENT_ID VARCHAR(255) DEFAULT NULL;
ALTER TABLE AM_API_COMMENTS ADD ENTRY_POINT VARCHAR(20);
ALTER TABLE AM_API_COMMENTS ADD CATEGORY VARCHAR(20) DEFAULT 'general';
ALTER TABLE AM_API_COMMENTS ADD FOREIGN KEY(PARENT_COMMENT_ID) REFERENCES AM_API_COMMENTS(COMMENT_ID);