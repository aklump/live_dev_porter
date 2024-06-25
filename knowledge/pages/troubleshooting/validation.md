<!--
id: validation
tags: ''
-->

# Validation Errors

If you are using the mysql plugin the validation will fail if you have the password in _config.local.yml_ alone. Until this bug is fixed you can get around it by adding `password: REDACTED` to _config.yml_. This will be overridden by the value of `password` in _config.local.yml_.
