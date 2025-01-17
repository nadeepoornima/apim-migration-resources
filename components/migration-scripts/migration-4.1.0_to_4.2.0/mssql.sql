IF NOT  EXISTS (SELECT * FROM SYS.OBJECTS WHERE OBJECT_ID = OBJECT_ID(N'[DBO].[AM_CORRELATION_CONFIGS]') AND TYPE IN (N'U'))
CREATE TABLE AM_CORRELATION_CONFIGS
(
    COMPONENT_NAME  VARCHAR(45)     NOT NULL,
    ENABLED         VARCHAR(45)     NOT NULL,
    PRIMARY KEY (COMPONENT_NAME)
);

IF NOT  EXISTS (SELECT * FROM SYS.OBJECTS WHERE OBJECT_ID = OBJECT_ID(N'[DBO].[AM_CORRELATION_PROPERTIES]') AND TYPE IN (N'U'))
CREATE TABLE AM_CORRELATION_PROPERTIES
(
    PROPERTY_NAME   VARCHAR(45)     NOT NULL,
    COMPONENT_NAME  VARCHAR(45)     NOT NULL,
    PROPERTY_VALUE  VARCHAR(1023)   NOT NULL,
    PRIMARY KEY (PROPERTY_NAME, COMPONENT_NAME),
    FOREIGN KEY (COMPONENT_NAME) REFERENCES AM_CORRELATION_CONFIGS(COMPONENT_NAME) ON DELETE CASCADE
);
