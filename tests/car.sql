-- a car to inherit _search.item
create table tests.car (
    brand text,
    model text,
    msrp numeric,
    doors int,
    check (type = 'car')
)
    inherits (_search.item);

-- car search params
create type tests.car_param_t as (
    name text,
    price numeric,
    doors int
);

-- returns car search param
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

-- car matching type
create type tests.car_match_it as (
    price_min numeric,
    price_max numeric,
    doors int
);

-- match a car
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

-- result as a jsonb
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
