# Migrating From Loft Deploy

1. `./vendor/aklump/live-dev-porter
   /live_dev_porter.sh config-migrate`
2. Review the contents of _.live_dev_porter_...
3. Fill in `@todo` appearing in the new config.
4. Rewrite any hooks as processors.
5. When convinced all is well, delete _.loft_deploy_
