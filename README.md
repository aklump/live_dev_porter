# Live Dev Porter

![live_dev_porter](images/live-dev-porter.jpg)

## Summary

Simplifies the management and transfer of assets between website environments.

**Visit <https://aklump.github.io/live_dev_porter> for full documentation.**

## Install with Composer

1. Require this package:
   
    ```
    composer require aklump/live-dev-porter:^0.0
    ```

## Quick Start

2. Ensure execute permissions: `chmod u+x ./vendor/bin/ldp`
3. Initialize your project using `./vendor/bin/ldp init`
4. (To migrate from Loft Deploy jump below...)
5. Open _.live\_dev\_porter/config.yml_ and modify as needed.
6. **Ensure _.live\_dev\_porter/config.local.yml_ is ignored by your SCM!**
7. Open _.live\_dev\_porter/config.local.yml_ and define the correct `local` and `remote` environment IDs as defined in _config.yml_.
8. Run `./vendor/bin/ldp configtest` and work through any failed tests.

### Migrating from Loft Deploy?

1. `rm .live_dev_porter/config*`
2. `./vendor/bin/ldp config-migrate .loft_deploy`
3. Rewrite any hooks as processors.
4. Return to where you left off above.

### Optional Shorthand `ldp` instead of `./vendor/bin/ldp`

#### Option A: `$PATH`

_This option has the advantage that any other composer binary in your project will be executable as well._

1. Add _/path/to/project/root/vendor/bin_ to your `$PATH`.

_~/.bash_profile_

```shell
PATH="/path/to/project/root/vendor/bin/ldp:$PATH"
```

#### Option B: alias

_This option is singularly focused in terms of what it affects._

_~/.bash_profile_

1. Add an alias called ldp that points to _/path/to/project/root/vendor/bin/ldp_.

```shell
alias ldp="/path/to/project/root/vendor/bin/ldp"
```

#### Both Options Continued

2. Type `ldp` to test if it worked... you should see available commands
3. Now use `ldp` from anywhere within your project, instead of `./vendor/bin/ldp` from the root.
4. Don't worry if you have more than one project using _Live Dev Porter_ because this alias will work for multiple projects as long as they use the same version, and usually even if the versions differ.

## Quick Start Remote

1. Deploy your code to your remote server.
2. On the remote server type `./vendor/bin/ldp config -l`

## Installation

The installation script above will generate the following structure where `.` is your repository root.

    .
    └── .live_dev_porter
    │   ├── config.local.yml
    │   └── config.yml
    └── {public web root}

## Configuration Files

Refer to the file(s) for documentation about configuration options.

| Filename | Description | VCS |
|----------|----------|---|
| _.live\_dev\_porter/config.yml_ | Configuration shared across all server environments: prod, staging, dev  | yes |
| _.live\_dev\_porter/config.local.yml_ | Configuration overrides for a single environment; not version controlled. | no |

## Usage

* To see all commands use `./vendor/bin/ldp`

## Sponsor this project


  <div><svg width="36" height="36" viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg"><circle cx="24" cy="24" r="20" fill="#181717"/><path d="M6.813 34.235a20.056 20.056 0 0 0 10.864 8.743c1 .183 1.366-.434 1.366-.965 0-.22-.004-.607-.01-1.126-.005-.602-.012-1.38-.018-2.275-5.563 1.209-6.736-2.681-6.736-2.681-.91-2.31-2.221-2.925-2.221-2.925-1.816-1.24.137-1.216.137-1.216 2.008.142 3.063 2.061 3.063 2.061 1.784 3.056 4.682 2.173 5.821 1.663.182-1.293.698-2.175 1.27-2.675-4.441-.504-9.11-2.22-9.11-9.884 0-2.183.78-3.969 2.059-5.367-.207-.506-.893-2.54.195-5.293 0 0 1.68-.538 5.5 2.05A19.154 19.154 0 0 1 24 13.672c1.698.008 3.41.23 5.007.673 3.819-2.588 5.495-2.05 5.495-2.05 1.091 2.754.405 4.787.198 5.293 1.282 1.398 2.057 3.183 2.057 5.366 0 7.684-4.677 9.375-9.132 9.87.718.617 1.358 1.837 1.358 3.704 0 1.787-.011 3.344-.019 4.376-.003.51-.006.892-.006 1.11 0 .535.36 1.157 1.375.962a20.043 20.043 0 0 0 9.207-6.386C35.873 41.11 30.274 44 24 44c-7.306 0-13.696-3.917-17.187-9.765z" fill="#fff"/></svg>
&nbsp;<a href="https://github.com/sponsors/aklump">github.com</a></div>

  <div><svg width="24" height="34" viewBox="0 0 27 39" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M14.32 17.912c-1.392.596-2.972 1.272-5.02 1.272a9.507 9.507 0 0 1-2.534-.35l1.416 14.543a2.43 2.43 0 0 0 2.422 2.23s2.008.104 2.678.104c.722 0 2.884-.104 2.884-.104a2.43 2.43 0 0 0 2.422-2.23l1.517-16.07c-.678-.231-1.363-.385-2.134-.385-1.334 0-2.409.459-3.65.99z" fill="#FD0"/><path d="M26.658 10.36l-.213-1.075c-.191-.965-.626-1.877-1.617-2.226-.317-.112-.677-.16-.921-.39-.244-.232-.316-.59-.372-.923-.104-.611-.202-1.222-.31-1.832-.091-.524-.164-1.113-.405-1.594-.313-.645-.962-1.023-1.608-1.273a9.27 9.27 0 0 0-1.01-.312c-1.614-.426-3.31-.582-4.97-.672a41.712 41.712 0 0 0-5.975.1C7.777.296 6.22.46 4.815.97c-.514.188-1.043.412-1.434.81-.48.487-.636 1.24-.286 1.849.25.432.67.737 1.117.939a9.05 9.05 0 0 0 1.814.59c1.737.384 3.535.535 5.31.599 1.966.079 3.936.015 5.893-.193a33.78 33.78 0 0 0 1.449-.191c.568-.087.932-.83.765-1.347-.2-.619-.739-.859-1.347-.765l-.269.04-.064.01c-.207.025-.413.05-.619.072-.426.046-.853.084-1.28.113a43.05 43.05 0 0 1-5.71.01 35.996 35.996 0 0 1-1.87-.173L8.1 3.311l-.04-.006-.192-.028a20.16 20.16 0 0 1-1.17-.208.176.176 0 0 1 0-.343h.008a18.975 18.975 0 0 1 1.353-.238h.003c.212-.014.425-.052.636-.077a40.497 40.497 0 0 1 5.533-.195 36.537 36.537 0 0 1 3.258.233c.073.01.147.02.22.028l.149.022c.431.064.86.142 1.288.234.633.138 1.446.182 1.728.876.09.22.13.465.18.696l.063.294a.383.383 0 0 1 .13 2.56h-.004l-.091.013-.09.012a55.401 55.401 0 0 1-2.554.271 59.293 59.293 0 0 1-5.107.206 59.883 59.883 0 0 1-7.588-.49c.191.024-.138-.02-.205-.029a43.803 43.803 0 0 1-.47-.068c-.525-.079-1.047-.176-1.57-.26-.634-.105-1.24-.053-1.813.26-.47.257-.852.652-1.092 1.132-.247.51-.32 1.067-.431 1.616-.11.55-.283 1.14-.218 1.704.14 1.217.991 2.205 2.215 2.427a64.094 64.094 0 0 0 18.32.607.78.78 0 0 1 .863.857l-.116 1.125-.7 6.822c-.243 2.388-.488 4.776-.735 7.163l-.208 2.017c-.067.661-.077 1.344-.202 1.998-.198 1.028-.895 1.66-1.91 1.891-.931.212-1.882.323-2.837.332-1.058.005-2.115-.042-3.173-.036-1.13.006-2.513-.098-3.385-.938-.766-.739-.872-1.895-.977-2.895-.139-1.323-.277-2.647-.413-3.97l-.767-7.358-.496-4.76-.024-.236c-.06-.568-.462-1.124-1.095-1.096-.543.024-1.16.485-1.096 1.095l.368 3.53.76 7.301.649 6.223c.041.397.08.795.124 1.193.239 2.171 1.897 3.342 3.95 3.671 1.2.193 2.429.233 3.646.253 1.56.025 3.136.085 4.671-.198 2.274-.417 3.98-1.936 4.224-4.291l.209-2.041.692-6.75.755-7.354.345-3.37a.782.782 0 0 1 .63-.688c.65-.127 1.272-.343 1.735-.838.736-.788.883-1.815.622-2.851zm-24.463.728c.01-.005-.008.08-.016.12-.001-.06.002-.113.016-.12zm.063.488c.006-.004.021.017.037.042-.024-.023-.04-.04-.037-.042zm.062.082c.023.038.035.062 0 0zm.125.101h.003c0 .004.006.007.008.011a.078.078 0 0 0-.011-.01zm21.826-.151c-.234.222-.586.325-.934.377-3.9.579-7.858.872-11.802.742-2.822-.096-5.615-.41-8.409-.804-.274-.039-.57-.089-.759-.29-.354-.381-.18-1.148-.088-1.608.085-.421.246-.983.748-1.043.782-.092 1.69.238 2.464.356a46.65 46.65 0 0 0 2.806.341c4.006.365 8.08.309 12.068-.225a50.281 50.281 0 0 0 2.173-.341c.643-.115 1.356-.332 1.744.334.267.454.302 1.061.261 1.574a.878.878 0 0 1-.273.587h.001z" fill="#0D0C22"/></svg>
&nbsp;<a href="https://buymeacoffee.com/aklump">buymeacoffee.com</a></div>

  <div><svg class="octicon octicon-link color-fg-muted" viewBox="0 0 16 16" width="24" height="24"><path d="M7.775 3.275l1.25-1.25a3.5 3.5 0 1 1 4.95 4.95l-2.5 2.5a3.5 3.5 0 0 1-4.95 0 .751.751 0 0 1 .018-1.042.751.751 0 0 1 1.042-.018 1.998 1.998 0 0 0 2.83 0l2.5-2.5a2.002 2.002 0 0 0-2.83-2.83l-1.25 1.25a.751.751 0 0 1-1.042-.018.751.751 0 0 1-.018-1.042zm-4.69 9.64a1.998 1.998 0 0 0 2.83 0l1.25-1.25a.751.751 0 0 1 1.042.018.751.751 0 0 1 .018 1.042l-1.25 1.25a3.5 3.5 0 1 1-4.95-4.95l2.5-2.5a3.5 3.5 0 0 1 4.95 0 .751.751 0 0 1-.018 1.042.751.751 0 0 1-1.042.018 1.998 1.998 0 0 0-2.83 0l-2.5 2.5a1.998 1.998 0 0 0 0 2.83z"/></svg>&nbsp;<a href="https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=4E5KZHDQCEUV8&item_name=Open%20Source%20Sponsorship">paypal.com</a></div>
