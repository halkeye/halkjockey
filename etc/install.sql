CREATE SEQUENCE user_id_seq INCREMENT BY 1 NO MAXVALUE MINVALUE 100 CACHE 1;
CREATE SEQUENCE song_id_seq INCREMENT BY 1 NO MAXVALUE MINVALUE 1 CACHE 1;

--mysql
--CREATE TABLE users (
--    id integer DEFAULT 1 NOT NULL PRIMARY KEY UNIQUE AUTO_INCREMENT,
--    username character varying(255) NOT NULL,
--    password character varying(32) DEFAULT '' NOT NULL
--);

--postgres
CREATE TABLE users (
    id integer DEFAULT nextval('"user_id_seq"'::text) NOT NULL PRIMARY KEY,
    username character varying(255) NOT NULL,
    password character varying(32) DEFAULT MD5('password') NOT NULL
);

CREATE TABLE songs (
    id integer DEFAULT nextval('"song_id_seq"'::text) NOT NULL PRIMARY KEY,
    filename character varying(255) NOT NULL UNIQUE,
    filename_nodir character varying(255) NOT NULL UNIQUE DEFAULT '',
    last_play TIMESTAMP DEFAULT NOW() NOT NULL,
    requested integer DEFAULT 0 NOT NULL CHECK ((requested >= 0))
);

CREATE TABLE requests (
    song_id integer DEFAULT 0 NOT NULL REFERENCES songs(id) ON UPDATE NO ACTION ON DELETE CASCADE,
    user_id integer DEFAULT 0 NOT NULL REFERENCES users(id) ON UPDATE NO ACTION ON DELETE CASCADE
);

INSERT INTO users (id, username, password) VALUES(0, 'global', '');
