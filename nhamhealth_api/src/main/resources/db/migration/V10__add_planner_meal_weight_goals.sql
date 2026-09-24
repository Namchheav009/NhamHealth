create table if not exists public.planner_meal_weight_goals (
    planner_meal_id integer not null,
    weight_goal varchar(30) not null,
    constraint pk_planner_meal_weight_goals primary key (planner_meal_id, weight_goal),
    constraint fk_planner_meal_weight_goals_meal
        foreign key (planner_meal_id)
        references public.planner_meals (planner_meal_id)
        on delete cascade,
    constraint ck_planner_meal_weight_goals_value
        check (weight_goal in ('LOSE_WEIGHT', 'MAINTAIN_HEALTH', 'GAIN_WEIGHT'))
);

insert into public.planner_meal_weight_goals (planner_meal_id, weight_goal)
select meal.planner_meal_id, goal.weight_goal
from public.planner_meals meal
cross join (
    values ('LOSE_WEIGHT'), ('MAINTAIN_HEALTH'), ('GAIN_WEIGHT')
) as goal(weight_goal)
on conflict (planner_meal_id, weight_goal) do nothing;

create index if not exists idx_planner_meal_weight_goals_goal
    on public.planner_meal_weight_goals (weight_goal, planner_meal_id);

alter table public.planner_meal_weight_goals enable row level security;
