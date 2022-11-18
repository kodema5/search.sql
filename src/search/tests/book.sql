\if :{?search_tests_book_sql}
\else
\set search_tests_book_sql true

\if :test
-- inherits _search.item
--
create table tests.book (
    title text,
    cover text,
    price numeric,
    check (type = 'book')
)
    inherits (_search.item);


-- book search param
create type tests.book_param_t as (
    title text,
    price numeric
);

-- returns book search param
create function tests.get_param (
    a tests.book
)
    returns tests.book_param_t
    language sql
    immutable
as $$
    select (
        a.title,
        a.price
    )::tests.book_param_t
$$;

-- extra book match
create type tests.book_only_match_it as (
    title text
);

-- book match type
create type tests.book_match_it as (
    price_min numeric,
    price_max numeric,
    book tests.book_only_match_it
);

-- match book
create function tests.match (
    p tests.book_param_t,
    m tests.book_match_it
)
    returns boolean
    language sql
    immutable
as $$
    select
        ( m.price_min is null or p.price >= m.price_min )
    and ( m.price_max is null or p.price < m.price_max )
    and ( m.book is null or (
        p.title is null or p.title ~ (m.book).title
    ))
$$;

-- transform to jsonb
create function tests.to_jsonb (
    a tests.book
)
    returns jsonb
    language sql
    immutable
as $$
    select jsonb_strip_nulls(jsonb_build_object(
        'type', 'book',
        'title', a.title,
        'price', a.price
    ))
$$;


\endif
\endif