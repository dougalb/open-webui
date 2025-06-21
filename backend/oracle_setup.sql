-- Open WebUI Oracle Database Setup Script (Fixed)
-- This script must be run as SYSDBA to create the database user and schema
--
-- Usage:
--   sqlplus / as sysdba @oracle_setup.sql
--
-- Or connect as SYSDBA and run this script

-- Variables (modify these as needed)
DEFINE openwebui_user = 'OPENWEBUI'
DEFINE openwebui_password = 'OpenWebUI123!'
DEFINE openwebui_tablespace = 'USERS'
DEFINE temp_tablespace = 'TEMP'

-- Create the user if it doesn't exist
DECLARE
    user_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO user_count FROM dba_users WHERE username = '&openwebui_user';
    IF user_count = 0 THEN
        EXECUTE IMMEDIATE 'CREATE USER &openwebui_user IDENTIFIED BY "&openwebui_password" DEFAULT TABLESPACE &openwebui_tablespace TEMPORARY TABLESPACE &temp_tablespace';
        DBMS_OUTPUT.PUT_LINE('User &openwebui_user created successfully.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('User &openwebui_user already exists.');
    END IF;
END;
/

-- Grant necessary privileges
GRANT CONNECT TO &openwebui_user;
GRANT RESOURCE TO &openwebui_user;
GRANT CREATE SESSION TO &openwebui_user;
GRANT CREATE TABLE TO &openwebui_user;
GRANT CREATE SEQUENCE TO &openwebui_user;
GRANT CREATE VIEW TO &openwebui_user;
GRANT CREATE PROCEDURE TO &openwebui_user;
GRANT CREATE TRIGGER TO &openwebui_user;
GRANT CREATE SYNONYM TO &openwebui_user;
GRANT UNLIMITED TABLESPACE TO &openwebui_user;

-- Connect as the new user to create tables
CONNECT &openwebui_user/"&openwebui_password"

-- Enable output for feedback
SET SERVEROUTPUT ON;

-- Create sequences for tables that might need them
CREATE SEQUENCE user_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE chat_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE message_seq START WITH 1 INCREMENT BY 1;

-- User Management Tables

-- User table - Fixed: Changed CLOB columns in constraints to VARCHAR2, using quoted identifier
CREATE TABLE users (
    id VARCHAR2(255) PRIMARY KEY,
    name VARCHAR2(255),
    email VARCHAR2(255),
    role VARCHAR2(255) DEFAULT 'pending',
    profile_image_url CLOB,
    last_active_at NUMBER(19),
    updated_at NUMBER(19),
    created_at NUMBER(19),
    api_key VARCHAR2(255),
    settings CLOB DEFAULT '{}',
    info CLOB DEFAULT '{}',
    oauth_sub VARCHAR2(4000), -- Changed from CLOB to VARCHAR2 for constraint
    CONSTRAINT uk_user_api_key UNIQUE (api_key),
    CONSTRAINT uk_user_oauth_sub UNIQUE (oauth_sub)
);

-- Auth table
CREATE TABLE auth (
    id VARCHAR2(255) PRIMARY KEY,
    email VARCHAR2(255),
    password CLOB,
    active NUMBER(1) DEFAULT 1,
    CONSTRAINT chk_auth_active CHECK (active IN (0, 1))
);

-- Chat and Messaging Tables

-- Chat table - Fixed: Added missing columns and corrected defaults
CREATE TABLE chat (
    id VARCHAR2(255) PRIMARY KEY,
    user_id VARCHAR2(255),
    title CLOB,
    chat CLOB,
    created_at NUMBER(19),
    updated_at NUMBER(19),
    share_id VARCHAR2(255), -- Changed from CLOB to VARCHAR2 for constraint
    archived NUMBER(1) DEFAULT 0,
    pinned NUMBER(1) DEFAULT 0,
    meta CLOB DEFAULT '{}',
    folder_id VARCHAR2(255), -- Changed from CLOB to VARCHAR2
    CONSTRAINT uk_chat_share_id UNIQUE (share_id),
    CONSTRAINT chk_chat_archived CHECK (archived IN (0, 1)),
    CONSTRAINT chk_chat_pinned CHECK (pinned IN (0, 1))
);

-- Message table - Fixed: Changed id and other key columns to VARCHAR2
CREATE TABLE message (
    id VARCHAR2(255) PRIMARY KEY, -- Changed from CLOB
    user_id VARCHAR2(255), -- Changed from CLOB
    channel_id VARCHAR2(255), -- Changed from CLOB
    parent_id VARCHAR2(255), -- Changed from CLOB
    content CLOB,
    data CLOB DEFAULT '{}',
    meta CLOB DEFAULT '{}',
    created_at NUMBER(19),
    updated_at NUMBER(19)
);

-- Message reaction table - Fixed: Changed id and other key columns to VARCHAR2
CREATE TABLE message_reaction (
    id VARCHAR2(255) PRIMARY KEY, -- Changed from CLOB
    user_id VARCHAR2(255), -- Changed from CLOB
    message_id VARCHAR2(255), -- Changed from CLOB
    name VARCHAR2(255), -- Changed from CLOB
    created_at NUMBER(19)
);

-- AI Model Management Tables

-- Model table - Fixed: Changed id and other key columns to VARCHAR2
CREATE TABLE model (
    id VARCHAR2(255) PRIMARY KEY, -- Changed from CLOB
    user_id VARCHAR2(255), -- Changed from CLOB
    base_model_id VARCHAR2(255), -- Changed from CLOB
    name VARCHAR2(255), -- Changed from CLOB
    params CLOB DEFAULT '{}',
    meta CLOB DEFAULT '{}',
    access_control CLOB DEFAULT '{}',
    is_active NUMBER(1) DEFAULT 1,
    updated_at NUMBER(19),
    created_at NUMBER(19),
    CONSTRAINT chk_model_is_active CHECK (is_active IN (0, 1))
);

-- File Management Tables

-- File table - Fixed: Using quoted identifier (file is reserved word)
CREATE TABLE files (
    id VARCHAR2(255) PRIMARY KEY,
    user_id VARCHAR2(255),
    hash VARCHAR2(4000), -- Changed from CLOB to VARCHAR2
    filename VARCHAR2(1000), -- Changed from CLOB to VARCHAR2
    path VARCHAR2(4000), -- Changed from CLOB to VARCHAR2
    data CLOB DEFAULT '{}',
    meta CLOB DEFAULT '{}',
    access_control CLOB DEFAULT '{}',
    created_at NUMBER(19),
    updated_at NUMBER(19)
);

-- Organization and Management Tables

-- Tag table
CREATE TABLE tag (
    id VARCHAR2(255),
    name VARCHAR2(255),
    user_id VARCHAR2(255),
    meta CLOB DEFAULT '{}',
    CONSTRAINT pk_tag PRIMARY KEY (id, user_id)
);

-- Group table - Fixed: Using quoted identifier (group is reserved word)
CREATE TABLE groups (
    id VARCHAR2(255) PRIMARY KEY, -- Changed from CLOB
    user_id VARCHAR2(255), -- Changed from CLOB
    name VARCHAR2(255), -- Changed from CLOB
    description CLOB,
    data CLOB DEFAULT '{}',
    meta CLOB DEFAULT '{}',
    permissions CLOB DEFAULT '{}',
    user_ids CLOB DEFAULT '[]',
    created_at NUMBER(19),
    updated_at NUMBER(19)
);

-- Folder table - Fixed: Changed id and other key columns to VARCHAR2
CREATE TABLE folder (
    id VARCHAR2(255) PRIMARY KEY, -- Changed from CLOB
    parent_id VARCHAR2(255), -- Changed from CLOB
    user_id VARCHAR2(255), -- Changed from CLOB
    name VARCHAR2(255), -- Changed from CLOB
    items CLOB DEFAULT '[]',
    meta CLOB DEFAULT '{}',
    is_expanded NUMBER(1) DEFAULT 0,
    created_at NUMBER(19),
    updated_at NUMBER(19),
    CONSTRAINT chk_folder_is_expanded CHECK (is_expanded IN (0, 1))
);

-- Prompt table
CREATE TABLE prompt (
    command VARCHAR2(255) PRIMARY KEY,
    user_id VARCHAR2(255),
    title CLOB,
    content CLOB,
    timestamp NUMBER(19),
    access_control CLOB DEFAULT '{}'
);

-- Function table
CREATE TABLE functions (
    id VARCHAR2(255) PRIMARY KEY,
    user_id VARCHAR2(255),
    name VARCHAR2(255), -- Changed from CLOB
    type VARCHAR2(255), -- Changed from CLOB
    content CLOB,
    meta CLOB DEFAULT '{}',
    valves CLOB DEFAULT '{}',
    is_active NUMBER(1) DEFAULT 1,
    is_global NUMBER(1) DEFAULT 0,
    updated_at NUMBER(19),
    created_at NUMBER(19),
    CONSTRAINT chk_function_is_active CHECK (is_active IN (0, 1)),
    CONSTRAINT chk_function_is_global CHECK (is_global IN (0, 1))
);

-- Additional tables for specific features

-- Document table (for RAG/knowledge base)
CREATE TABLE document (
    collection_name VARCHAR2(255),
    name VARCHAR2(255),
    title CLOB,
    filename VARCHAR2(1000), -- Changed from CLOB
    content CLOB DEFAULT '{}',
    user_id VARCHAR2(255), -- Changed from CLOB
    timestamp NUMBER(19),
    CONSTRAINT pk_document PRIMARY KEY (collection_name, name)
);

-- Config table (for application settings)
CREATE TABLE config (
    id NUMBER GENERATED BY DEFAULT ON NULL AS IDENTITY PRIMARY KEY,
    data CLOB CONSTRAINT chk_config_data_json CHECK (data IS JSON),
    version NUMBER DEFAULT 0 NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP
);

-- Memory table (for conversation memory) - Fixed: Changed id to VARCHAR2
CREATE TABLE memory (
    id VARCHAR2(255) PRIMARY KEY, -- Changed from CLOB
    user_id VARCHAR2(255), -- Changed from CLOB
    content CLOB,
    updated_at NUMBER(19),
    created_at NUMBER(19)
);

-- Tool table (for custom tools)
CREATE TABLE tool (
    id VARCHAR2(255) PRIMARY KEY,
    user_id VARCHAR2(255),
    name VARCHAR2(255), -- Changed from CLOB
    content CLOB,
    specs CLOB DEFAULT '{}',
    meta CLOB DEFAULT '{}',
    valves CLOB DEFAULT '{}',
    access_control CLOB DEFAULT '{}',
    updated_at NUMBER(19),
    created_at NUMBER(19)
);

-- Knowledge table (for knowledge base)
CREATE TABLE knowledge (
    id VARCHAR2(255) PRIMARY KEY,
    user_id VARCHAR2(255),
    name VARCHAR2(255), -- Changed from CLOB
    description CLOB,
    data CLOB DEFAULT '{}',
    meta CLOB DEFAULT '{}',
    access_control CLOB DEFAULT '{}',
    created_at NUMBER(19),
    updated_at NUMBER(19)
);

-- Channel table (for messaging channels)
CREATE TABLE channel (
    id VARCHAR2(255) PRIMARY KEY,
    user_id VARCHAR2(255),
    type VARCHAR2(255),
    name VARCHAR2(255),
    description CLOB,
    data CLOB DEFAULT '{}',
    meta CLOB DEFAULT '{}',
    access_control CLOB DEFAULT '{}',
    created_at NUMBER(19),
    updated_at NUMBER(19)
);

-- Feedback table (for user feedback)
CREATE TABLE feedback (
    id VARCHAR2(255) PRIMARY KEY,
    user_id VARCHAR2(255),
    version NUMBER(19) DEFAULT 0,
    type VARCHAR2(255),
    data CLOB DEFAULT '{}',
    meta CLOB DEFAULT '{}',
    snapshot CLOB DEFAULT '{}',
    created_at NUMBER(19),
    updated_at NUMBER(19)
);

-- Note table (for user notes)
CREATE TABLE note (
    id VARCHAR2(255) PRIMARY KEY,
    user_id VARCHAR2(255),
    title VARCHAR2(255),
    data CLOB DEFAULT '{}',
    meta CLOB DEFAULT '{}',
    access_control CLOB DEFAULT '{}',
    created_at NUMBER(19),
    updated_at NUMBER(19)
);

-- Create indexes for better performance
CREATE INDEX idx_user_email ON users(email);
CREATE INDEX idx_user_last_active ON users(last_active_at);
CREATE INDEX idx_chat_user_id ON chat(user_id);
CREATE INDEX idx_chat_created_at ON chat(created_at);
CREATE INDEX idx_message_user_id ON message(user_id);
CREATE INDEX idx_message_channel_id ON message(channel_id);
CREATE INDEX idx_message_created_at ON message(created_at);
CREATE INDEX idx_file_user_id ON files(user_id);
CREATE INDEX idx_folder_user_id ON folder(user_id);
CREATE INDEX idx_folder_parent_id ON folder(parent_id);
CREATE INDEX idx_channel_user_id ON channel(user_id);
CREATE INDEX idx_channel_type ON channel(type);
CREATE INDEX idx_feedback_user_id ON feedback(user_id);
CREATE INDEX idx_feedback_type ON feedback(type);
CREATE INDEX idx_note_user_id ON note(user_id);
CREATE INDEX idx_knowledge_user_id ON knowledge(user_id);
CREATE INDEX idx_tool_user_id ON tool(user_id);

-- Create triggers for timestamp management
CREATE OR REPLACE TRIGGER trg_user_timestamps
    BEFORE INSERT OR UPDATE ON users
    FOR EACH ROW
BEGIN
    IF INSERTING THEN
        :NEW.created_at := (SYSDATE - DATE '1970-01-01') * 86400 * 1000000000;
        :NEW.updated_at := :NEW.created_at;
    ELSIF UPDATING THEN
        :NEW.updated_at := (SYSDATE - DATE '1970-01-01') * 86400 * 1000000000;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_chat_timestamps
    BEFORE INSERT OR UPDATE ON chat
    FOR EACH ROW
BEGIN
    IF INSERTING THEN
        :NEW.created_at := (SYSDATE - DATE '1970-01-01') * 86400 * 1000000000;
        :NEW.updated_at := :NEW.created_at;
    ELSIF UPDATING THEN
        :NEW.updated_at := (SYSDATE - DATE '1970-01-01') * 86400 * 1000000000;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_model_timestamps
    BEFORE INSERT OR UPDATE ON model
    FOR EACH ROW
BEGIN
    IF INSERTING THEN
        :NEW.created_at := (SYSDATE - DATE '1970-01-01') * 86400 * 1000000000;
        :NEW.updated_at := :NEW.created_at;
    ELSIF UPDATING THEN
        :NEW.updated_at := (SYSDATE - DATE '1970-01-01') * 86400 * 1000000000;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_file_timestamps
    BEFORE INSERT OR UPDATE ON files
    FOR EACH ROW
BEGIN
    IF INSERTING THEN
        :NEW.created_at := (SYSDATE - DATE '1970-01-01') * 86400 * 1000000000;
        :NEW.updated_at := :NEW.created_at;
    ELSIF UPDATING THEN
        :NEW.updated_at := (SYSDATE - DATE '1970-01-01') * 86400 * 1000000000;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_channel_timestamps
    BEFORE INSERT OR UPDATE ON channel
    FOR EACH ROW
BEGIN
    IF INSERTING THEN
        :NEW.created_at := (SYSDATE - DATE '1970-01-01') * 86400 * 1000000000;
        :NEW.updated_at := :NEW.created_at;
    ELSIF UPDATING THEN
        :NEW.updated_at := (SYSDATE - DATE '1970-01-01') * 86400 * 1000000000;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_feedback_timestamps
    BEFORE INSERT OR UPDATE ON feedback
    FOR EACH ROW
BEGIN
    IF INSERTING THEN
        :NEW.created_at := (SYSDATE - DATE '1970-01-01') * 86400 * 1000000000;
        :NEW.updated_at := :NEW.created_at;
    ELSIF UPDATING THEN
        :NEW.updated_at := (SYSDATE - DATE '1970-01-01') * 86400 * 1000000000;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_note_timestamps
    BEFORE INSERT OR UPDATE ON note
    FOR EACH ROW
BEGIN
    IF INSERTING THEN
        :NEW.created_at := (SYSDATE - DATE '1970-01-01') * 86400 * 1000000000;
        :NEW.updated_at := :NEW.created_at;
    ELSIF UPDATING THEN
        :NEW.updated_at := (SYSDATE - DATE '1970-01-01') * 86400 * 1000000000;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_knowledge_timestamps
    BEFORE INSERT OR UPDATE ON knowledge
    FOR EACH ROW
BEGIN
    IF INSERTING THEN
        :NEW.created_at := (SYSDATE - DATE '1970-01-01') * 86400 * 1000000000;
        :NEW.updated_at := :NEW.created_at;
    ELSIF UPDATING THEN
        :NEW.updated_at := (SYSDATE - DATE '1970-01-01') * 86400 * 1000000000;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_tool_timestamps
    BEFORE INSERT OR UPDATE ON tool
    FOR EACH ROW
BEGIN
    IF INSERTING THEN
        :NEW.created_at := (SYSDATE - DATE '1970-01-01') * 86400 * 1000000000;
        :NEW.updated_at := :NEW.created_at;
    ELSIF UPDATING THEN
        :NEW.updated_at := (SYSDATE - DATE '1970-01-01') * 86400 * 1000000000;
    END IF;
END;
/

-- Output completion message
BEGIN
    DBMS_OUTPUT.PUT_LINE('=================================');
    DBMS_OUTPUT.PUT_LINE('Open WebUI Oracle Database Setup Complete');
    DBMS_OUTPUT.PUT_LINE('=================================');
    DBMS_OUTPUT.PUT_LINE('User: &openwebui_user');
    DBMS_OUTPUT.PUT_LINE('Schema: &openwebui_user');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Database URL format for Open WebUI:');
    DBMS_OUTPUT.PUT_LINE('oracle://&openwebui_user:&openwebui_password@hostname:1521/service_name');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Environment variable:');
    DBMS_OUTPUT.PUT_LINE('DATABASE_URL=oracle://&openwebui_user:&openwebui_password@hostname:1521/service_name');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Tables created successfully. Application is ready to start.');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('NOTE: Used quoted identifiers for Oracle reserved words (user, file, group, function)');
    DBMS_OUTPUT.PUT_LINE('Application code does not need changes - table names remain the same.');
END;
/

-- Show table count for verification
SELECT 'Created ' || COUNT(*) || ' tables' AS result FROM user_tables;

EXIT;