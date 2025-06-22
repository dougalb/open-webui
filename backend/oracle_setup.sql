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

-- User Management Tables

-- Users table - Fixed: Changed CLOB columns in constraints to VARCHAR2, using quoted identifier
CREATE TABLE users (
    id VARCHAR2(36) PRIMARY KEY,
    name VARCHAR2(255),
    email VARCHAR2(255),
    role VARCHAR2(32) DEFAULT 'pending',
    profile_image_url VARCHAR2(4000),
    last_active_at NUMBER(19),
    updated_at NUMBER(19),
    created_at NUMBER(19),
    api_key VARCHAR2(128),
    settings VARCHAR2(4000) DEFAULT '{}' CHECK (settings IS JSON),
    info VARCHAR2(4000) DEFAULT '{}' CHECK (info IS JSON),
    oauth_sub VARCHAR2(255),
    CONSTRAINT uk_user_api_key UNIQUE (api_key),
    CONSTRAINT uk_user_oauth_sub UNIQUE (oauth_sub)
);

-- Auth table
CREATE TABLE auth (
    id VARCHAR2(36) PRIMARY KEY,                -- Use 36 if you store UUIDs
    email VARCHAR2(255) NOT NULL UNIQUE,        -- Emails should not be null; enforce uniqueness if appropriate
    password VARCHAR2(255) NOT NULL,            -- Use VARCHAR2, not CLOB, for password hashes
    active NUMBER(1) DEFAULT 1 NOT NULL,
    CONSTRAINT chk_auth_active CHECK (active IN (0, 1))
);

-- Chat and Messaging Tables

-- Chat table - Fixed: Added missing columns and corrected defaults
CREATE TABLE chat (
    id VARCHAR2(36) PRIMARY KEY,                        -- Use 36 for UUID
    user_id VARCHAR2(36) NOT NULL,                      -- Use 36 for UUID
    title VARCHAR2(255),                                -- VARCHAR2 unless titles can be huge
    chat CLOB,                                          -- Body/transcript, CLOB is appropriate
    created_at NUMBER(19) NOT NULL,                     -- Unix timestamp
    updated_at NUMBER(19) NOT NULL,                     -- Unix timestamp
    share_id VARCHAR2(36),                              -- UUID/token, use 36 chars
    archived NUMBER(1) DEFAULT 0 NOT NULL,
    pinned NUMBER(1) DEFAULT 0 NOT NULL,
    meta CLOB DEFAULT '{}',                             -- Or VARCHAR2(4000) CHECK (meta IS JSON)
    folder_id VARCHAR2(36),                             -- UUID for folders
    CONSTRAINT uk_chat_share_id UNIQUE (share_id),
    CONSTRAINT chk_chat_archived CHECK (archived IN (0, 1)),
    CONSTRAINT chk_chat_pinned CHECK (pinned IN (0, 1))
    -- Optional: Add FOREIGN KEY (user_id) REFERENCES users(id)
    -- Optional: Add FOREIGN KEY (folder_id) REFERENCES folders(id)
);

-- Message table - Fixed: Changed id and other key columns to VARCHAR2
CREATE TABLE message (
    id VARCHAR2(36) PRIMARY KEY,                 -- Use 36 for UUID
    user_id VARCHAR2(36) NOT NULL,               -- Use 36 for UUID; NOT NULL if always required
    channel_id VARCHAR2(36) NOT NULL,            -- Use 36 for UUID; NOT NULL if always required
    parent_id VARCHAR2(36),                      -- Use 36 for UUID; nullable for root messages
    content CLOB,
    data CLOB DEFAULT '{}',                      -- Or VARCHAR2(4000) CHECK (data IS JSON)
    meta CLOB DEFAULT '{}',                      -- Or VARCHAR2(4000) CHECK (meta IS JSON)
    created_at NUMBER(19) NOT NULL,
    updated_at NUMBER(19) NOT NULL
    -- Optional: Add FOREIGN KEY (user_id) REFERENCES users(id)
    -- Optional: Add FOREIGN KEY (channel_id) REFERENCES channel(id)
    -- Optional: Add FOREIGN KEY (parent_id) REFERENCES message(id)
);

-- Message reaction table - Fixed: Changed id and other key columns to VARCHAR2
CREATE TABLE message_reaction (
    id VARCHAR2(36) PRIMARY KEY,          -- UUID
    user_id VARCHAR2(36) NOT NULL,        -- UUID, not null
    message_id VARCHAR2(36) NOT NULL,     -- UUID, not null
    name VARCHAR2(64) NOT NULL,           -- Short name for reaction (emoji, etc)
    created_at NUMBER(19) NOT NULL       -- Unix timestamp
    -- Optional: Add FOREIGN KEY (user_id) REFERENCES users(id),
    -- Optional: Add FOREIGN KEY (message_id) REFERENCES message(id)
);

-- Optional: Add indexes for performance if needed:
-- CREATE INDEX idx_reaction_message_id ON message_reaction(message_id);
-- CREATE INDEX idx_reaction_user_id ON message_reaction(user_id);

-- AI Model Management Tables

-- Model table - Fixed: Changed id and other key columns to VARCHAR2
CREATE TABLE model (
    id VARCHAR2(36) PRIMARY KEY,             -- UUID for primary key
    user_id VARCHAR2(36) NOT NULL,           -- UUID, not null
    base_model_id VARCHAR2(36),              -- Nullable, self-ref FK possible
    name VARCHAR2(255) NOT NULL,             -- Model name
    params CLOB DEFAULT '{}',                -- JSON, CLOB for flexibility
    meta CLOB DEFAULT '{}',                  -- JSON, CLOB for flexibility
    access_control CLOB DEFAULT '{}',        -- JSON, CLOB for flexibility
    is_active NUMBER(1) DEFAULT 1 NOT NULL,  -- Boolean with default
    updated_at NUMBER(19) NOT NULL,          -- Unix timestamp
    created_at NUMBER(19) NOT NULL,          -- Unix timestamp
    CONSTRAINT chk_model_is_active CHECK (is_active IN (0, 1))
    -- Optional: Add FOREIGN KEY (user_id) REFERENCES users(id)
    -- Optional: Add FOREIGN KEY (base_model_id) REFERENCES model(id)
);

-- File Management Tables

-- Files table
CREATE TABLE files (
    id VARCHAR2(36) PRIMARY KEY,               -- UUID
    user_id VARCHAR2(36) NOT NULL,             -- UUID, not null
    hash VARCHAR2(128) NOT NULL,               -- File hash, not null
    filename VARCHAR2(255) NOT NULL,           -- Shortened for efficiency, not null
    path VARCHAR2(1000),                       -- Increased from default but usually not >1000
    data CLOB,                                 -- File content
    meta CLOB DEFAULT '{}',                    -- Metadata JSON
    access_control CLOB DEFAULT '{}',          -- JSON for access control
    created_at NUMBER(19) NOT NULL,            -- Unix timestamp
    updated_at NUMBER(19) NOT NULL             -- Unix timestamp
    -- Optional: Add FOREIGN KEY (user_id) REFERENCES users(id)
    -- Optional: Add UNIQUE (hash) -- if hashes must be unique
);

-- Optional indexes for performance:
-- CREATE INDEX idx_files_user_id ON files(user_id);
-- CREATE INDEX idx_files_hash ON files(hash);

-- Organization and Management Tables

-- Tag table
CREATE TABLE tag (
    id VARCHAR2(36) NOT NULL,                     -- UUID
    name VARCHAR2(255) NOT NULL,                  -- Tag name
    user_id VARCHAR2(36) NOT NULL,                -- UUID for user
    meta CLOB DEFAULT '{}',                       -- Metadata as JSON
    CONSTRAINT pk_tag PRIMARY KEY (id, user_id)
    -- Optional: Add unique constraint to avoid duplicate tag names per user:
    -- CONSTRAINT uk_tag_name_per_user UNIQUE (name, user_id)
    -- Optional: Add foreign key:
    -- CONSTRAINT fk_tag_user FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Group table - Fixed: Using quoted identifier (group is reserved word)
CREATE TABLE groups (
    id VARCHAR2(36) PRIMARY KEY,                -- UUID
    user_id VARCHAR2(36) NOT NULL,              -- UUID, owner of the group
    name VARCHAR2(255) NOT NULL,                -- Group name
    description CLOB,                           -- Optional long text
    data CLOB DEFAULT '{}',                     -- Arbitrary JSON
    meta CLOB DEFAULT '{}',                     -- Metadata JSON
    permissions CLOB DEFAULT '{}',              -- Permissions JSON
    user_ids CLOB DEFAULT '[]',                 -- List of users as JSON array
    created_at NUMBER(19) NOT NULL,             -- Unix timestamp
    updated_at NUMBER(19) NOT NULL              -- Unix timestamp
    -- Optional: Add FOREIGN KEY (user_id) REFERENCES users(id)
    -- Optional: Add UNIQUE (name, user_id) if needed
);

-- Optional: Index for fast queries by user_id:
-- CREATE INDEX idx_groups_user_id ON groups(user_id);

-- Folder table - Fixed: Changed id and other key columns to VARCHAR2
CREATE TABLE folder (
    id VARCHAR2(36) PRIMARY KEY,                    -- UUID
    parent_id VARCHAR2(36),                         -- UUID for parent folder (nullable for root)
    user_id VARCHAR2(36) NOT NULL,                  -- UUID, owner
    name VARCHAR2(255) NOT NULL,                    -- Folder name
    items CLOB DEFAULT '[]',                        -- JSON array for items
    meta CLOB DEFAULT '{}',                         -- JSON metadata
    is_expanded NUMBER(1) DEFAULT 0 NOT NULL,       -- Boolean flag
    created_at NUMBER(19) NOT NULL,                 -- Unix timestamp
    updated_at NUMBER(19) NOT NULL,                 -- Unix timestamp
    CONSTRAINT chk_folder_is_expanded CHECK (is_expanded IN (0, 1))
    -- Optional: FOREIGN KEY (parent_id) REFERENCES folder(id),
    -- Optional: FOREIGN KEY (user_id) REFERENCES users(id),
    -- Optional: UNIQUE (user_id, name) -- if needed
);

-- Optional indexes:
-- CREATE INDEX idx_folder_user_id ON folder(user_id);
-- CREATE INDEX idx_folder_parent_id ON folder(parent_id);

-- Prompt table
CREATE TABLE prompt (
    command VARCHAR2(255) PRIMARY KEY,        -- Unique identifier for prompt
    user_id VARCHAR2(36) NOT NULL,            -- UUID, not null
    title VARCHAR2(255),                      -- Use VARCHAR2 unless titles are very long
    content CLOB NOT NULL,                    -- Prompt content
    timestamp NUMBER(19) NOT NULL,            -- Unix timestamp
    access_control CLOB DEFAULT '{}'          -- JSON access control
    -- Optional: Add FOREIGN KEY (user_id) REFERENCES users(id)
    -- Optional: Add UNIQUE (command, user_id)
);

-- Function table
CREATE TABLE functions (
    id VARCHAR2(36) PRIMARY KEY,                  -- UUID, PK
    user_id VARCHAR2(36) NOT NULL,                -- UUID, FK, not null
    name VARCHAR2(255) NOT NULL,                  -- Function name
    type VARCHAR2(64) NOT NULL,                   -- Type/category (short)
    content CLOB NOT NULL,                        -- Function body/text
    meta CLOB DEFAULT '{}',                       -- JSON metadata
    valves CLOB DEFAULT '{}',                     -- JSON for settings/params
    is_active NUMBER(1) DEFAULT 1 NOT NULL,       -- Boolean
    is_global NUMBER(1) DEFAULT 0 NOT NULL,       -- Boolean
    updated_at NUMBER(19) NOT NULL,               -- Unix timestamp
    created_at NUMBER(19) NOT NULL,               -- Unix timestamp
    CONSTRAINT chk_function_is_active CHECK (is_active IN (0, 1)),
    CONSTRAINT chk_function_is_global CHECK (is_global IN (0, 1))
    -- Optional: FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Optional: Index for user_id
-- CREATE INDEX idx_functions_user_id ON functions(user_id);

-- Additional tables for specific features

-- Document table (for RAG/knowledge base)
CREATE TABLE document (
    collection_name VARCHAR2(255) NOT NULL,       -- Document collection, PK part
    name VARCHAR2(255) NOT NULL,                  -- Document name/ID, PK part
    title VARCHAR2(255),                          -- Use VARCHAR2 unless titles are often long
    filename VARCHAR2(255),                       -- 255 is typical for filenames
    content CLOB DEFAULT '{}',                    -- Large document body or JSON
    user_id VARCHAR2(36) NOT NULL,                -- UUID for user, not null
    timestamp NUMBER(19) NOT NULL,                -- Unix timestamp
    CONSTRAINT pk_document PRIMARY KEY (collection_name, name)
    -- Optional: FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Optional: Index for user_id
-- CREATE INDEX idx_document_user_id ON document(user_id);

-- Config table (for application settings)
CREATE TABLE config (
    id NUMBER GENERATED BY DEFAULT ON NULL AS IDENTITY PRIMARY KEY,
    data CLOB CONSTRAINT chk_config_data_json CHECK (data IS JSON),
    version NUMBER DEFAULT 0 NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP
    -- CONSTRAINT chk_config_version_nonneg CHECK (version >= 0)
);

-- Memory table (for conversation memory) - Fixed: Changed id to VARCHAR2
CREATE TABLE memory (
    id VARCHAR2(36) PRIMARY KEY,            -- UUID
    user_id VARCHAR2(36) NOT NULL,          -- UUID, not null
    content CLOB NOT NULL,                  -- Memory text/content
    updated_at NUMBER(19) NOT NULL,         -- Unix timestamp
    created_at NUMBER(19) NOT NULL          -- Unix timestamp
    -- Optional: FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Optional: Index for user_id
-- CREATE INDEX idx_memory_user_id ON memory(user_id);

-- Tool table (for custom tools)
CREATE TABLE tool (
    id VARCHAR2(36) PRIMARY KEY,            -- UUID, PK
    user_id VARCHAR2(36) NOT NULL,          -- UUID, not null
    name VARCHAR2(255) NOT NULL,            -- Tool name, not null
    content CLOB NOT NULL,                  -- Tool description/code
    specs CLOB DEFAULT '{}',                -- JSON specs
    meta CLOB DEFAULT '{}',                 -- JSON metadata
    valves CLOB DEFAULT '{}',               -- JSON settings
    access_control CLOB DEFAULT '{}',       -- JSON ACL
    updated_at NUMBER(19) NOT NULL,         -- Unix timestamp
    created_at NUMBER(19) NOT NULL          -- Unix timestamp
    -- Optional: FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Optional: Index for user_id
-- CREATE INDEX idx_tool_user_id ON tool(user_id);

-- Knowledge table (for knowledge base)
CREATE TABLE knowledge (
    id VARCHAR2(36) PRIMARY KEY,            -- UUID, PK
    user_id VARCHAR2(36) NOT NULL,          -- UUID, not null
    name VARCHAR2(255) NOT NULL,            -- Knowledge base name
    description CLOB,                       -- Long-form text
    data CLOB DEFAULT '{}',                 -- JSON data
    meta CLOB DEFAULT '{}',                 -- JSON metadata
    access_control CLOB DEFAULT '{}',       -- JSON ACL
    created_at NUMBER(19) NOT NULL,         -- Unix timestamp
    updated_at NUMBER(19) NOT NULL          -- Unix timestamp
    -- Optional: FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Optional: Index for user_id
-- CREATE INDEX idx_knowledge_user_id ON knowledge(user_id);

-- Channel table (for messaging channels)
CREATE TABLE channel (
    id VARCHAR2(36) PRIMARY KEY,             -- UUID, PK
    user_id VARCHAR2(36) NOT NULL,           -- UUID, not null
    type VARCHAR2(64) NOT NULL,              -- Channel type (short), not null
    name VARCHAR2(255) NOT NULL,             -- Channel name, not null
    description CLOB,                        -- Long description
    data CLOB DEFAULT '{}',                  -- JSON data
    meta CLOB DEFAULT '{}',                  -- JSON metadata
    access_control CLOB DEFAULT '{}',        -- JSON ACL
    created_at NUMBER(19) NOT NULL,          -- Unix timestamp
    updated_at NUMBER(19) NOT NULL           -- Unix timestamp
    -- Optional: FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Optional indexes:
-- CREATE INDEX idx_channel_user_id ON channel(user_id);
-- CREATE INDEX idx_channel_type ON channel(type);

-- Feedback table (for user feedback)
CREATE TABLE feedback (
    id VARCHAR2(36) PRIMARY KEY,            -- UUID, PK
    user_id VARCHAR2(36) NOT NULL,          -- UUID, FK, not null
    version NUMBER(19) DEFAULT 0 NOT NULL,  -- Version, non-negative, not null
    type VARCHAR2(64) NOT NULL,             -- Short type/label, not null
    data CLOB DEFAULT '{}',                 -- JSON data
    meta CLOB DEFAULT '{}',                 -- JSON metadata
    snapshot CLOB DEFAULT '{}',             -- JSON state/snapshot
    created_at NUMBER(19) NOT NULL,         -- Unix timestamp
    updated_at NUMBER(19) NOT NULL          -- Unix timestamp
    -- Optional: CONSTRAINT chk_feedback_version_nonneg CHECK (version >= 0)
    -- Optional: FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Optional indexes:
-- CREATE INDEX idx_feedback_user_id ON feedback(user_id);
-- CREATE INDEX idx_feedback_type ON feedback(type);

-- Note table (for user notes)
CREATE TABLE note (
    id VARCHAR2(36) PRIMARY KEY,            -- UUID, PK
    user_id VARCHAR2(36) NOT NULL,          -- UUID, FK to users, not null
    title VARCHAR2(255) NOT NULL,           -- Note title, not null
    data CLOB DEFAULT '{}',                 -- Note content, JSON
    meta CLOB DEFAULT '{}',                 -- Metadata, JSON
    access_control CLOB DEFAULT '{}',       -- Access control, JSON
    created_at NUMBER(19) NOT NULL,         -- Unix timestamp
    updated_at NUMBER(19) NOT NULL          -- Unix timestamp
    -- Optional: FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Optional: Index for user_id
-- CREATE INDEX idx_note_user_id ON note(user_id);

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

-- Output completion message
BEGIN
    DBMS_OUTPUT.PUT_LINE('=================================');
    DBMS_OUTPUT.PUT_LINE('Open WebUI Oracle Database Setup Complete');
    DBMS_OUTPUT.PUT_LINE('=================================');
    DBMS_OUTPUT.PUT_LINE('User: &openwebui_user');
    DBMS_OUTPUT.PUT_LINE('Schema: &openwebui_user');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Database URL format for Open WebUI:');
    DBMS_OUTPUT.PUT_LINE('oracle://&openwebui_user:&openwebui_password@hostname:1521?service_name=SERVICE');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Environment variable:');
    DBMS_OUTPUT.PUT_LINE('DATABASE_URL=oracle://&openwebui_user:&openwebui_password@hostname:1521?service_name=SERVICE');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Tables created successfully. Application is ready to start.');
END;
/

-- Show table count for verification
SELECT 'Created ' || COUNT(*) || ' tables' AS result FROM user_tables;

EXIT;