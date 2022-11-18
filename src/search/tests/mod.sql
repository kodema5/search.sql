\if :{?search_tests_mod_sql}
\else
\set search_tests_mod_sql true

\if :test

\ir car.sql
\ir book.sql

create function tests.test_search_get()
    returns setof text
    language plpgsql
as $$
declare
    n int;
begin
    -- register book type
    --
    call search.set_type (
        id_ => 'book',

        table_t_ => 'tests.book'::regclass,
        param_t_  =>'tests.book_param_t'::regtype,
        match_it_ => 'tests.book_match_it'::regtype,
        code_sch => 'tests'
    );

    insert into tests.book (type, title, price)
    values
        ('book', 'cars and horses', 100),
        ('book', 'code and cpus', 200);


    -- register a car type
    -- a trigger will be added to auto-build the param
    --
    call search.set_type (
        id_ => 'car',

        table_t_ => 'tests.car'::regclass,
        param_t_  =>'tests.car_param_t'::regtype,
        match_it_ =>'tests.car_match_it'::regtype,

        param_f_ =>'tests.get_param(tests.car)'::regprocedure,
        match_f_ =>'tests.match(tests.car_param_t,tests.car_match_it)'::regprocedure,
        jsonb_f_ =>'tests.to_jsonb(tests.car)'::regprocedure
    );

    insert into tests.car (type, brand, model, doors, msrp)
    values
        ('car', 'honda', 'civic ', 3, 100),
        ('car', 'honda', 'accord', 4, 200);

    select count(1) into n
    from search.get(jsonb_build_object(
        'price_min', 90,
        'price_max', 110
    ));
    return next ok(n = 2, 'able to search');


    select count(1) into n
    from search.get(jsonb_build_object(
        'types', array['car'],
        'price_min', 90,
        'price_max', 110
    ));
    return next ok(n = 1, 'able to search only for car');

    call search.unset_type('car');
    call search.unset_type('book');
end;
$$;

\endif

\endif