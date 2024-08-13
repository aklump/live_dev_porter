<?php

namespace AKlump\LiveDevPorter\Processors;

abstract class ProcessorBase {

  const TOKENS__PASSWORD = "PASSWORD";

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

  /**
   * @param $processor_config
   *   This is not runtime config, but the processor args/config!
   */
  public function __construct($processor_config) {
    $this->config = $processor_config;
    $this->command = $processor_config['COMMAND'] ?? '';
    $this->databaseId = $processor_config['DATABASE_ID'] ?? '';
    $this->databaseName = $processor_config['DATABASE_NAME'] ?? '';
    $this->filesGroupId = $processor_config['FILES_GROUP_ID'] ?? '';
    $this->config['FILEPATH'] = $processor_config['FILEPATH'] ?? '';
    $this->shortpath = $processor_config['SHORTPATH'] ?? '';
  }

  /**
   * Get the sandboxed environment variable name.
   *
   * @param string $variable_name
   *
   * @return string
   *   The value of the sandboxed environment variable.
   */
  protected function getEnv(string $variable_name): string {
    return strval($this->config[$variable_name]) ?? '';
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

  public function getExtension(): string {
    return $this->getFileInfo()['extension'] ?? '';
  }

  public function getFilepath(): string {
    return $this->getFileInfo()['filepath'] ?? '';
  }

  public function getBasename(): string {
    return $this->getFileInfo()['basename'] ?? '';
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
      return FALSE;
    }
    $save_result = file_put_contents($this->config['FILEPATH'], $this->loadedFile['contents']);
    if (FALSE === $save_result) {
      throw new ProcessorFailedException(sprintf('Failed to save: %s', $this->config['FILEPATH']));
    }
    if ($move && $move !== $this->config['FILEPATH']) {
      $move_result = rename($this->config['FILEPATH'], $move);
      if (FALSE === $move_result) {
        throw new ProcessorFailedException(sprintf("Could not move file to: %s", $move));
      }
      $this->config['FILEPATH'] = $move;
    }

    return TRUE;
  }

  protected function validateFileIsLoaded() {
    if (!array_key_exists('original', $this->loadedFile)) {
      throw new ProcessorFailedException('::loadFile has not yet been called.');
    }
  }

  protected function query(string $statement) {
    // TODO Copy the code from processor_support.sh
  }

}
