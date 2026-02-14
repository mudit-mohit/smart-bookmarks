-- Smart Bookmarks Database Schema
-- Run this in Supabase SQL Editor

-- Create bookmarks table
create table bookmarks (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users not null,
  title text not null,
  url text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable Row Level Security
alter table bookmarks enable row level security;

-- Create policies to ensure users can only access their own bookmarks
create policy "Users can view their own bookmarks"
  on bookmarks for select
  using (auth.uid() = user_id);

create policy "Users can insert their own bookmarks"
  on bookmarks for insert
  with check (auth.uid() = user_id);

create policy "Users can delete their own bookmarks"
  on bookmarks for delete
  using (auth.uid() = user_id);

-- Enable real-time subscriptions for live updates
alter publication supabase_realtime add table bookmarks;

-- Create index for faster queries
create index bookmarks_user_id_idx on bookmarks(user_id);
create index bookmarks_created_at_idx on bookmarks(created_at desc);