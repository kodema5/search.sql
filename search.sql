-- how to create an abstract search?
-- supposed to have a set of products
-- where each product has own attributes
-- one approach is to make a superset of columns
-- is there another way?

create extension if not exists "uuid-ossp" schema public;
create extension if not exists pgcrypto schema public;
create extension if not exists ltree schema public;

-- data
\if :local
    drop schema if exists _search cascade;
\endif
create schema if not exists _search;
\ir src/_search/index.sql


-- api
drop schema if exists search cascade;
create schema search;
\ir src/search/index.sql


\ir tests/index.sql

-- faq
-- the approach is to have each item cache a jsonb param column
-- then to cast it for a match.
-- why not directly access param column with jsonb operator?
-- a preference, found it easier to use types and functions