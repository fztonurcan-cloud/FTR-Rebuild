-- Phase 37: cover the reviewer foreign key used by exercise safety review joins/deletes.
create index if not exists exercise_safety_reviews_reviewed_by_idx
on private.exercise_safety_reviews (reviewed_by);
