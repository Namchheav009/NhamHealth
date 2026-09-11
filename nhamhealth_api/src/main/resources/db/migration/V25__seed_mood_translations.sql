-- Ensure English translations are populated for all moods
insert into public.mood_translations (mood_id, language_code, name)
select mood_id, 'en', mood_name from public.moods
on conflict (mood_id, language_code) do update set name = excluded.name;

-- Seed Khmer translations for standard moods
insert into public.mood_translations (mood_id, language_code, name)
select m.mood_id, 'km', km.name
from public.moods m
join (values
    ('Happy', 'សប្បាយរីករាយ'),
    ('Great', 'អស្ចារ្យ'),
    ('Excited', 'រំភើប'),
    ('Joyful', 'រីករាយ'),
    ('Loved', 'មានក្ដីស្រឡាញ់'),
    ('Calm', 'ស្ងប់ស្ងាត់'),
    ('Relaxed', 'ធូរស្រាល'),
    ('Grateful', 'ដឹងគុណ'),
    ('Motivated', 'មានទឹកចិត្ត'),
    ('Focused', 'ផ្តោតអារម្មណ៍'),
    ('Energized', 'មានថាមពល'),
    ('Hopeful', 'មានក្តីសង្ឃឹម'),
    ('Okay', 'ធម្មតា'),
    ('Proud', 'មានមោទនភាព'),
    ('Playful', 'រួសរាយ'),
    ('Curious', 'ចង់ដឹងចង់ឃើញ'),
    ('Surprised', 'ភ្ញាក់ផ្អើល'),
    ('Confident', 'មានទំនុកចិត្ត'),
    ('Peaceful', 'សុខសាន្ត'),
    ('Relieved', 'ធូរទ្រូង'),
    ('Busy', 'រវល់'),
    ('Tired', 'អស់កម្លាំង'),
    ('Sleepy', 'ងងុយគេង'),
    ('Stressed', 'តានតឹង'),
    ('Anxious', 'ព្រួយបារម្ភ'),
    ('Overwhelmed', 'លើសលប់'),
    ('Confused', 'ច្របូកច្របល់'),
    ('Bored', 'អផ្សុក'),
    ('Sad', 'កើតទុក្ខ'),
    ('Lonely', 'ឯកោ'),
    ('Angry', 'ខឹង'),
    ('Frustrated', 'មួម៉ៅ'),
    ('Disappointed', 'ខកចិត្ត'),
    ('Embarrassed', 'ខ្មាសអៀន'),
    ('Nervous', 'ភ័យ'),
    ('Afraid', 'ខ្លាច'),
    ('Hurt', 'ឈឺចាប់'),
    ('Jealous', 'ច្រណែន'),
    ('Drained', 'អស់កម្លាំងល្ហិតល្ហៃ'),
    ('Restless', 'មិនស្រណុកក្នុងចិត្ត'),
    ('Sick', 'ឈឺ'),
    ('Hungry', 'ឃ្លាន')
) as km(mood_name, name) on lower(m.mood_name) = lower(km.mood_name)
on conflict (mood_id, language_code) do update set name = excluded.name;
