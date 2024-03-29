DROP TABLE ASSOCIATIONS;
DROP TABLE INDEX;
DROP TABLE SUBMISSIONS;
DROP TABLE ASSIGNMENTS;
DROP TABLE OFFERINGS;
DROP TABLE CLASSES;
DROP TABLE USERS;

CREATE EXTENSION pgcrypto;

CREATE TABLE public.USERS (
    ID SERIAL PRIMARY KEY,
    USERNAME VARCHAR(50) NOT NULL UNIQUE,
    PASSWORD VARCHAR(50) NOT NULL
);

ALTER TABLE public.USERS
    OWNER to waterfern;

CREATE TABLE public.CLASSES(
    ID SERIAL PRIMARY KEY,
    COURSECODE VARCHAR(8) NOT NULL
);

ALTER TABLE public.CLASSES
    OWNER to waterfern;

CREATE TABLE public.OFFERINGS(
    ID SERIAL PRIMARY KEY,
    CLASS_ID INT,
    SEMESTER DATE,
    DONE INT,
    FOREIGN KEY(CLASS_ID) REFERENCES CLASSES(ID)
);

ALTER TABLE public.OFFERINGS
    OWNER to waterfern;

CREATE TABLE public.OFFERING_OWNERS(
    USERID INT NOT NULL, 
    OFFERINGID INT NOT NULL,
    FOREIGN KEY(USERID) REFERENCES USERS(ID),
    FOREIGN KEY(OFFERINGID) REFERENCES OFFERINGS(ID)
);

ALTER TABLE public.OFFERING_OWNERS
    OWNER to waterfern;

CREATE TABLE public.ASSIGNMENTS(
    ID SERIAL PRIMARY KEY,
    OFFERING_ID INT,
    OPENING DATE,
    CLOSE DATE,
    FOREIGN KEY(OFFERING_ID) REFERENCES OFFERINGS(ID)
);

ALTER TABLE public.ASSIGNMENTS
    OWNER to waterfern;

CREATE TABLE public.SUBMISSIONS(
    ID SERIAL PRIMARY KEY,
    ASSIGN_ID INT,
    USER_ID INT,
    LATE INT,
    DATA BYTEA,
    NAME VARCHAR,
    LENGTH INT,
    LANGUAGE VARCHAR,
    SIMILARITY NUMERIC DEFAULT 0.0,
    ASSOCIATIONCOUNT INT DEFAULT 1,
    FOREIGN KEY(ASSIGN_ID) REFERENCES ASSIGNMENTS(ID),
    FOREIGN KEY(USER_ID) REFERENCES USERS
);
ALTER TABLE public.SUBMISSIONS
    OWNER to waterfern;

CREATE TABLE public.INDEX(
    BLOCK_ID SERIAL NOT NULL UNIQUE,
    SUBMISSION_ID INT NOT NULL,
    START_LINE INT NOT NULL,
    END_LINE INT NOT NULL,
    INDEX REAL[] NOT NULL,
    TYPE VARCHAR NOT NULL,
    PRIMARY KEY (SUBMISSION_ID, START_LINE, END_LINE, TYPE),
    FOREIGN KEY (SUBMISSION_ID) REFERENCES SUBMISSIONS(ID)
);
ALTER TABLE public.INDEX
    OWNER to waterfern;

CREATE TABLE public.ASSOCIATIONS(
    DOCUMENT1 INT NOT NULL, 
    DOCUMENT2 INT NOT NULL, 
    INDEX1 INT NOT NULL, 
    INDEX2 INT NOT NULL, 
    SIMILARITY NUMERIC NOT NULL,
    FOREIGN KEY (DOCUMENT1) REFERENCES SUBMISSIONS(ID),
    FOREIGN KEY (DOCUMENT2) REFERENCES SUBMISSIONS(ID),
    FOREIGN KEY (INDEX1) REFERENCES INDEX(BLOCK_ID),
    FOREIGN KEY (INDEX2) REFERENCES INDEX(BLOCK_ID)
);
ALTER TABLE public.ASSOCIATIONS
    OWNER to waterfern;

CREATE TABLE public.PROGRESS(
    SUBMISSION_ID INT NOT NULL,
    INDEXER_ID VARCHAR(50) NOT NULL,
    FOREIGN KEY (SUBMISSION_ID) REFERENCES SUBMISSIONS(ID)
);
ALTER TABLE public.PROGRESS
    OWNER to waterfern;

INSERT INTO CLASSES (ID,COURSECODE) VALUES (0,'memes123');
INSERT INTO OFFERINGS (ID, CLASS_ID, SEMESTER, DONE) VALUES (0,0, '2017-01-01',0);

INSERT INTO ASSIGNMENTS (ID, OFFERING_ID, OPENING, CLOSE) VALUES (0,0,'2017-01-01','2017-01-01');

INSERT INTO USERS (ID,USERNAME, PASSWORD) VALUES (0,'Paetric', crypt('pass', 'abcd'));  

INSERT INTO OFFERING_OWNERS (USERID, OFFERINGID) VALUES (0,0);

CREATE OR REPLACE FUNCTION update_the_score()
    RETURNS trigger AS 
$BODY$
BEGIN 
    UPDATE SUBMISSIONS 
        SET SIMILARITY = SUBMISSIONS.SIMILARITY + NEW.SIMILARITY, ASSOCIATIONCOUNT = SUBMISSIONS.ASSOCIATIONCOUNT + 1
        WHERE SUBMISSIONs.ID = NEW.DOCUMENT1 or SUBMISSIONS.ID = NEW.DOCUMENT2;

    RETURN NULL;
END;
$BODY$ LANGUAGE plpgsql;

CREATE TRIGGER update_similarity_score
AFTER INSERT ON ASSOCIATIONS
    FOR EACH ROW EXECUTE PROCEDURE update_the_score();
