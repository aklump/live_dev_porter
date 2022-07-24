# On Dreamhost, Export Failed Due to PHP Version

1. On the remote server.
2. Open _~/.bashrd_
3. Add this line, adjusting as appropriate: `PATH="/usr/local/php74/bin:$PATH"`

The problem was that PHP 7.4 was being added in _~/.bash_profile_ which is only for login shells.  The export connects with a non-login shell and so the default php was getting loaded.  By placing it in _~/.bashrc_ it gets loaded.
