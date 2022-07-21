<?php

namespace AKlump\LiveDevPorter\Processors;

abstract class ProcessorBase {

  /**
   * @var string
   */
  protected $command;

  /**
   * @var string
   */
  protected $databaseId;

  /**
   * @var string
   */
  protected $databaseName;

  /**
   * @var string
   */
  protected $filesGroupId;

  /**
   * @var string
   */
  protected $shortpath;

  /**
   * @var array
   */
  protected $loadedFile = [];

  /**
   * @var string
   */
  protected $output;

  /**
   * @var array
   */
  private $config;

  public function __construct($config) {
    $this->config = $config;
    $this->command = $config['COMMAND'] ?? '';
    $this->databaseId = $config['DATABASE_ID'] ?? '';
    $this->databaseName = $config['DATABASE_NAME'] ?? '';
    $this->filesGroupId = $config['FILES_GROUP_ID'] ?? '';
    $this->config['FILEPATH'] = $config['FILEPATH'] ?? '';
    $this->shortpath = $config['SHORTPATH'] ?? '';
  }

  /**
   * Get source environment info.
   *
   * @return array
   *   Information about the source environment.
   */
  protected function getSourceEnvironment(): array {
    if ($this->command === 'pull') {
      return ['id' => $this->config['REMOTE_ENV_ID']];
    }

    return ['id' => $this->config['LOCAL_ENV_ID']];
  }

  /**
   * Generate a filepath based on the source environment.
   *
   * @code
   * $move_to = $this->getSourceBasedFilepath([
   *   'dev' => 'dev',
   *   'local' => 'dev',
   *   'live' => 'prod',
   * ]);
   * $this->saveFile($move_to);
   * @endcode
   *
   * @param array $map
   *   An array which maps environment ids to their corresponding file extension
   *   prefix.  Keys are environment ids and the values are modifiers that will
   *   be appended to dotfiles and prepended to the extensions of all other
   *   files.
   *
   * @return string
   *   The new filepath with the extension modified if the source environment is
   *   matched to an item in $map.  Otherwise the original filepath is returned
   *   without modification.
   */
  protected function getSourceBasedFilepath(array $map): string {
    $source = $this->getSourceEnvironment()['id'];
    $info = $this->getFileInfo();
    $modifier = $map[$source] ?? NULL;
    if (is_null($modifier)) {
      return $info['filepath'];
    }
    if (strpos($info['basename'], '.') === 0) {
      return sprintf('%s.%s', $info['filepath'], $modifier);
    }

    return sprintf('%s/%s.%s.%s',
      $info['dirname'], $info['filename'], $modifier, $info['extension']
    );
  }

  protected function isWriteableEnvironment(): bool {
    return $this->config['IS_WRITEABLE_ENVIRONMENT'] ?? FALSE;
  }

  protected function getFileInfo() {
    if (empty($this->config['FILEPATH'])) {
      return [];
    }

    return ['filepath' => $this->config['FILEPATH']] + pathinfo($this->config['FILEPATH']);
  }

  /**
   * Load the contents of a file.
   *
   * @param string $filepath
   *
   * @return bool
   *   FALSE if $filepath is empty.  TRUE if $filepath was loaded.
   * @throws \AKlump\LiveDevPorter\Processors\ProcessorFailedException If the does not exist or cannot be loaded.
   */
  protected function loadFile() {
    $filepath = $this->config['FILEPATH'];
    if (empty($filepath)) {
      return FALSE;
    }

    if (!file_exists($filepath)) {
      throw new ProcessorFailedException(sprintf('The file %s does not exist.', $filepath));
    }

    $this->loadedFile = [];
    $contents = file_get_contents($filepath);
    if (FALSE === $contents) {
      throw new ProcessorFailedException(sprintf('The file %s could not be read.', $this->shortpath));

    }
    $this->loadedFile['contents'] = $contents;
    $this->loadedFile['original'] = $contents;

    return TRUE;
  }

  /**
   * Save any loaded file changes.
   *
   * @param string $move
   *   Move the file to a different location on save.
   *
   * @return bool
   *   If the contents have not changed since loading AND $move is not being
   *   used (null or the original path), false is returned;
   *   otherwise true on success saving of the file.  Errors are thrown as
   *   exceptions.
   *
   * @throws \AKlump\LiveDevPorter\Processors\ProcessorFailedException If the file could not be saved.
   */
  protected function saveFile(string $move = NULL) {
    $this->validateFileIsLoaded();
    $is_moving = $move !== NULL && $move !== $this->config['FILEPATH'];
    if (!$is_moving && $this->loadedFile['contents'] === $this->loadedFile['original']) {
      return TRUE;
    }

    $result = file_put_contents($this->config['FILEPATH'], $this->loadedFile['contents']);
    if (FALSE === $result) {
      throw new ProcessorFailedException(sprintf('Failed to save: %s', $this->config['FILEPATH']));
    }
    if ($move && $move !== $this->config['FILEPATH']) {
      $result = rename($this->config['FILEPATH'], $move);
      if (FALSE === $result) {
        throw new ProcessorFailedException(sprintf("Could not move file to: %s", $move));
      }
      $this->config['FILEPATH'] = $move;
    }

    return $result;
  }

  protected function validateFileIsLoaded() {
    if (!array_key_exists('original', $this->loadedFile)) {
      throw new ProcessorFailedException(sprintf('You must call ::loadFile before calling %s; nothing to save', __FUNCTION__));
    }
  }

  protected function query(string $statement) {
    // TODO Copy the code from processor_support.sh
  }

}
