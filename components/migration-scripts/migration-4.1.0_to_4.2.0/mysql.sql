CREATE TABLE IF NOT EXISTS AM_CORRELATION_CONFIGS (
    COMPONENT_NAME  VARCHAR(45)     NOT NULL,
    ENABLED         VARCHAR(45)     NOT NULL,
    PRIMARY KEY (COMPONENT_NAME)
)ENGINE INNODB;

CREATE TABLE IF NOT EXISTS AM_CORRELATION_PROPERTIES(
    PROPERTY_NAME   VARCHAR(45)     NOT NULL,
    COMPONENT_NAME  VARCHAR(45)     NOT NULL,
    PROPERTY_VALUE  VARCHAR(1023)   NOT NULL,
    PRIMARY KEY (PROPERTY_NAME, COMPONENT_NAME),
    FOREIGN KEY (COMPONENT_NAME) REFERENCES AM_CORRELATION_CONFIGS(COMPONENT_NAME) ON DELETE CASCADE
)ENGINE INNODB;
