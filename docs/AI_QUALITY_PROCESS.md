# NhamHealth AI quality process

## Release gate

Every vision model or prompt change must be evaluated against a versioned dataset before release. The dataset should contain clear and difficult images, Khmer dishes, mixed plates, drinks, packaging, poor lighting, and non-food images. Do not store faces, documents, or unrelated personal information.

1. Duplicate `tools/ai-eval/evaluation.csv` and add one row per labeled case.
2. Run the candidate model and record its prediction, nutrition, and confidence without changing the expected columns.
3. Run `powershell -File tools/ai-eval/run-evaluation.ps1` from the repository root.
4. Compare results with the previous model and prompt version.
5. Block release if high-confidence errors increase, abstention gets worse, or calorie/protein error regresses materially.

Start with at least 100 cases and grow toward 500. Keep a permanent holdout set that is never used while editing prompts.

## Metrics

- Exact food recognition accuracy
- Calories and protein mean absolute error
- Correct abstention rate for non-food and unusable images
- High-confidence error count
- User confirmation and correction rates
- Database-match rate
- Provider failure and local-fallback rate
- Median and p95 response latency
- Cost per completed analysis

## Feedback review

The app sends confirmations and corrections to the authenticated analysis record. Review corrections by model name and prompt version each week. Add frequent, verified corrections to food aliases or the evaluation dataset. Never train directly on unreviewed user input.

## Deployment configuration

No production credential belongs in Git. Configure `NVIDIA_API_KEY`, `NHAMHEALTH_JWT_SECRET`, `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `SUPABASE_URL`, `SUPABASE_SERVICE_KEY`, `DATABASE_URL`, `DATABASE_USERNAME`, `DATABASE_PASSWORD`, `MAIL_USERNAME`, and `MAIL_PASSWORD` in the deployment secret manager.

Rotate every credential that was previously committed, then remove those values from Git history before sharing the repository. The working-tree cleanup in this change does not invalidate old credentials or erase prior commits.

## Safety boundaries

- AI results are wellness estimates, not diagnoses or official labels.
- Users must confirm uncertain food and portion results before logging.
- Nutrition should come from the curated database when a reliable match exists.
- Recommendation models may rank only supplied meal IDs and must never invent nutrition.
- Add structured allergy and dietary-preference fields before using those attributes. Allergies must be hard filters in application code, not prompt-only instructions.
