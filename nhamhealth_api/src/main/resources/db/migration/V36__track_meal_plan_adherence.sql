alter table public.meal_plans
    add column status varchar(20) not null default 'PLANNED',
    add column completed_at timestamp(6),
    add column actual_servings numeric(6,2),
    add constraint ck_meal_plans_status
        check (status in ('PLANNED', 'EATEN', 'SKIPPED')),
    add constraint ck_meal_plans_actual_servings
        check (actual_servings is null or (actual_servings > 0 and actual_servings <= 20));

create index idx_meal_plans_user_date_status
    on public.meal_plans (user_id, plan_date, status);
