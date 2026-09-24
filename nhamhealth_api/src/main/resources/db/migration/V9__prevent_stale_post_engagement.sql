-- Remove engagement rows whose original post no longer exists. Without a
-- parent constraint these rows can be attached to a new post if a development
-- database resets/reuses its user_meal_post identity sequence.
DELETE FROM public.comment_likes
WHERE comment_id IN (
    SELECT comment_id
    FROM public.post_comments
    WHERE user_meal_post_id NOT IN (
        SELECT user_meal_post_id FROM public.user_meal_posts
    )
);

DELETE FROM public.post_comments
WHERE user_meal_post_id NOT IN (
    SELECT user_meal_post_id FROM public.user_meal_posts
);

DELETE FROM public.post_likes
WHERE user_meal_post_id NOT IN (
    SELECT user_meal_post_id FROM public.user_meal_posts
);

-- Enforce ownership at the database boundary as well as in RecipeFlowService.
-- The service still performs explicit cleanup for related tables and media.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_post_likes_user_meal_post'
    ) THEN
        ALTER TABLE public.post_likes
            ADD CONSTRAINT fk_post_likes_user_meal_post
            FOREIGN KEY (user_meal_post_id)
            REFERENCES public.user_meal_posts (user_meal_post_id)
            ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_post_comments_user_meal_post'
    ) THEN
        ALTER TABLE public.post_comments
            ADD CONSTRAINT fk_post_comments_user_meal_post
            FOREIGN KEY (user_meal_post_id)
            REFERENCES public.user_meal_posts (user_meal_post_id)
            ON DELETE CASCADE;
    END IF;
END
$$;
