-- creating database
CREATE DATABASE :dbname;

-- creating user with all privileges
CREATE USER :username;
GRANT ALL PRIVILEGES ON DATABASE :dbname TO :username;
ALTER USER :username WITH PASSWORD :userpassword;
ALTER USER :username WITH SUPERUSER;
