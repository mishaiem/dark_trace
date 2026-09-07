-- Run this file in Supabase SQL Editor. The app only uses the publishable anon key.
create table if not exists public.profiles (user_id uuid primary key references auth.users(id) on delete cascade, display_name text not null default 'Trace Runner', avatar_url text, coins integer not null default 0 check (coins >= 0), total_score bigint not null default 0 check (total_score >= 0), created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create table if not exists public.levels (id integer primary key, title text not null, config jsonb not null default '{}'::jsonb, active boolean not null default true);
create table if not exists public.player_progress (user_id uuid references auth.users(id) on delete cascade, level_id integer references public.levels(id), best_score integer not null default 0, best_time numeric, stars integer not null default 0 check (stars between 0 and 3), attempts integer not null default 0, coins_earned integer not null default 0, completed boolean not null default false, updated_at timestamptz not null default now(), primary key (user_id, level_id));
create table if not exists public.leaderboard_scores (id bigint generated always as identity primary key, user_id uuid references auth.users(id) on delete cascade, level_id integer, score integer not null, created_at timestamptz not null default now());
create table if not exists public.achievements (id text primary key, title text not null, description text not null, target integer not null default 1);
create table if not exists public.user_achievements (user_id uuid references auth.users(id) on delete cascade, achievement_id text references public.achievements(id), progress integer not null default 0, unlocked_at timestamptz, primary key (user_id, achievement_id));
create table if not exists public.cosmetics (id text primary key, category text not null, title text not null, price integer not null check (price >= 0), config jsonb not null default '{}'::jsonb);
create table if not exists public.user_cosmetics (user_id uuid references auth.users(id) on delete cascade, cosmetic_id text references public.cosmetics(id), equipped boolean not null default false, primary key (user_id, cosmetic_id));
create table if not exists public.daily_challenges (day date primary key, config jsonb not null);
create table if not exists public.daily_challenge_results (user_id uuid references auth.users(id) on delete cascade, day date references public.daily_challenges(day), score integer not null default 0, completed boolean not null default false, primary key (user_id, day));
create index if not exists leaderboard_scores_score_idx on public.leaderboard_scores(score desc);

alter table public.profiles enable row level security; alter table public.player_progress enable row level security; alter table public.user_achievements enable row level security; alter table public.user_cosmetics enable row level security; alter table public.daily_challenge_results enable row level security;
create policy "own profile" on public.profiles for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own progress" on public.player_progress for select using (auth.uid() = user_id);
create policy "own achievements" on public.user_achievements for select using (auth.uid() = user_id);
create policy "own cosmetics" on public.user_cosmetics for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own daily result" on public.daily_challenge_results for select using (auth.uid() = user_id);

create or replace function public.submit_level_score(p_level_id integer, p_score integer, p_time numeric, p_stars integer, p_coins integer) returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null or p_score < 0 or p_stars not between 0 and 3 or p_coins < 0 then raise exception 'invalid score'; end if;
  insert into player_progress(user_id, level_id, best_score, best_time, stars, coins_earned, completed, attempts) values(auth.uid(), p_level_id, p_score, p_time, p_stars, p_coins, true, 1)
  on conflict(user_id, level_id) do update set best_score = greatest(player_progress.best_score, excluded.best_score), best_time = least(coalesce(player_progress.best_time, excluded.best_time), excluded.best_time), stars = greatest(player_progress.stars, excluded.stars), coins_earned = player_progress.coins_earned + excluded.coins_earned, completed = true, attempts = player_progress.attempts + 1, updated_at = now();
  insert into leaderboard_scores(user_id, level_id, score) values(auth.uid(), p_level_id, p_score);
end; $$;

insert into achievements(id,title,description,target) values ('first_trace','First Trace','Complete your first level',1),('perfect_shadow','Perfect Shadow','Complete a level without shadow hits',1),('collector','Collector','Collect 50 coins',50),('untouchable','Untouchable','Complete 5 perfect levels',5),('speed_demon','Speed Demon','Beat 10 target times',10),('shadow_master','Shadow Master','Complete level 30',1),('daily_hunter','Daily Hunter','Complete 7 daily challenges',7) on conflict do nothing;
insert into cosmetics(id,category,title,price) values ('violet_core','skin','Violet Core',0),('cyan_trace','trail','Cyan Trace',100),('long_shadow','shadow','Long Shadow',250) on conflict do nothing;
