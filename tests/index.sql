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