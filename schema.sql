-- TODO: Figure out defaults and stuff.
CREATE TABLE `characters` (
  `identifier` integer NOT NULL PRIMARY KEY AUTOINCREMENT
,  `user` varchar(30) DEFAULT NULL
,  `name` varchar(30) DEFAULT NULL
,  `state` integer DEFAULT NULL
,  `room` integer DEFAULT NULL
,  `description` mediumtext
,  `colour` integer DEFAULT NULL
,  `cmdset` integer DEFAULT NULL
,  `pronouns` integer DEFAULT NULL
,  `hp` integer DEFAULT NULL
);

CREATE TABLE `objects` (
  `identifier` integer NOT NULL PRIMARY KEY AUTOINCREMENT
,  `name` varchar(30) NOT NULL DEFAULT ''
,  `description` mediumtext NOT NULL DEFAULT ''
,  `container` integer NOT NULL DEFAULT 0
,  `container_t` integer NOT NULL DEFAULT '0'
);

CREATE TABLE `pronouns` (
  `identifier` integer NOT NULL PRIMARY KEY AUTOINCREMENT
,  `i` varchar(10) DEFAULT NULL
,  `myself` varchar(10) DEFAULT NULL
,  `mine` varchar(10) DEFAULT NULL
,  `my` varchar(10) DEFAULT NULL
);

CREATE TABLE `rooms` (
  `identifier` integer NOT NULL PRIMARY KEY AUTOINCREMENT
,  `description` mediumtext NOT NULL DEFAULT ''
,  `name` varchar(100) NOT NULL DEFAULT ''
,  `flags` integer NOT NULL DEFAULT '0'
,  `exits` varchar(150) NOT NULL DEFAULT ''
);

CREATE TABLE `user_scripts` (
  `identifier` integer NOT NULL
,  `type` integer NOT NULL DEFAULT '0'
,  `name` varchar(50) NOT NULL
,  `body` mediumtext NOT NULL
,  UNIQUE (`identifier`,`type`)
);

CREATE TABLE `users` (
  `username` varchar(20) DEFAULT NULL
,  `password` varchar(32) DEFAULT NULL
,  `email` varchar(64) NOT NULL
,  `salt` varbinary(64) NOT NULL
,  UNIQUE (`username`)
);

-- Defaults:
INSERT INTO rooms(identifier,description,name) VALUES(1, "A plain white room. With work, it could become something great.", "Canvas");

REPLACE INTO pronouns VALUES (1, "he","himself","his","his");
REPLACE INTO pronouns VALUES (2, "she","herself","hers","her");
REPLACE INTO pronouns VALUES (3, "they","themself","theirs","their");
REPLACE INTO pronouns VALUES (4, "you","yourself","yours","your");
