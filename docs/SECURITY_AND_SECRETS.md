# Security and secrets

This public archive intentionally excludes:
- shinyapps.io tokens and secrets;
- `.Rhistory`, `.RData`, and `rsconnect/` deployment metadata;
- local credential files;
- patient-level datasets.

Deployment credentials must be supplied through secure environment variables or the local authenticated `rsconnect` configuration and must never be committed to a public repository.
