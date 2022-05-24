\if :test


    create table tests.car (
        brand text,
        model text,
        msrp numeric,
        doors int,
        check (type = 'car')
    )
        inherits (_search.item);


    create type tests.car_param_t as (
        name text,
        price numeric,
        doors int
    );

    create function tests.get_param (
        a tests.car
    )
        returns tests.car_param_t
        language sql
        immutable
    as $$
        select (
            a.brand  || ' ' || a.model,
            a.msrp,
            a.doors
        )::tests.car_param_t
    $$;

    create type tests.car_match_it as (
        price_min numeric,
        price_max numeric,
        doors int
    );

    create function tests.match (
        p tests.car_param_t,
        m tests.car_match_it
    )
        returns boolean
        -- language plpgsql -- for debug purpose
        language sql -- for inlining
        immutable
    as $$
    -- begin
    --     raise warning '--- p? %', p;
    --     raise warning '--- m? %', m;
    --     return (
        select
            ( m.price_min is null or p.price >= m.price_min )
        and ( m.price_max is null or p.price < m.price_max )
        and ( m.doors is null or p.doors = m.doors )
    --     );
    -- end;
    $$;


    create function tests.to_jsonb (
        a tests.car
    )
        returns jsonb
        language sql
        immutable
    as $$
        select jsonb_strip_nulls(jsonb_build_object(
            'type', 'car',
            'name', a.brand  || ' ' || a.model,
            'price', a.msrp
        ))
    $$;

    --------------------------------------------------------------------------

    create table tests.book (
        title text,
        cover text,
        price numeric,
        check (type = 'book')
    )
        inherits (_search.item);



    create type tests.book_param_t as (
        title text,
        price numeric
    );

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

    create type tests.book_only_match_it as (
        title text
    );

    create type tests.book_match_it as (
        price_min numeric,
        price_max numeric,
        book tests.book_only_match_it
    );

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

    --------------------------------------------------------------------------
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

    --------------------------------------------------------------------------

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

    --------------------------------------------------------------------------

    create function tests.test_search_get()
        returns setof text
        language plpgsql
    as $$
    declare
        n int;
    begin
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