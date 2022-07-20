# Source Files, Not Used for Validation

These files get compiled by \AKlump\LiveDevPorter\Config\SchemaBuilder into .live_dev_porter/.cache, at which point they are used for validation. In other words, these are source files, which are dynamically modified and never used for validation.

For example an array like this `"enum": ["ENVIRONMENT_IDS"]` will be interpolated and replaced with realtime configuration environment ids.
