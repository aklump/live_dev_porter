<?php

namespace AKlump\LiveDevPorter\Processors;

use PhpParser\Error;
use PhpParser\Node;
use PhpParser\Node\Expr\Variable;
use PhpParser\NodeTraverser;
use PhpParser\NodeVisitor\ParentConnectingVisitor;
use PhpParser\ParserFactory;

/**
 * @deprecated Since version 0.0.160, Use \AKlump\LiveDevPorter\Processors\RedactPasswords instead.
 */
trait PhpTrait {

  /**
   * @param string $variable_name
   *   E.g., 'databases.default.default.password'
   * @param string $replace_with
   *
   * @return void
   */
  protected function phpReplaceValue(string $variable_name, string $replace_with = '') {
    $this->validateFileIsLoaded();
    if (empty($this->loadedFile['contents'])) {
      return;
    }
    $value_to_replace = (string) $this->getValueByVariableDeclaration($variable_name);
    $total_replacements = 0;
    $this->loadedFile['contents'] = str_replace($value_to_replace, $replace_with, $this->loadedFile['contents'], $total_replacements);
    if ($total_replacements < 1) {
      throw new ProcessorFailedException(sprintf('%s was not found in the file.  Nothing to replace.', $variable_name));
    }
  }

  private function getValueByVariableDeclaration(string $variable_name) {
    try {
      $factory = new ParserFactory();
      $parser = $factory->create(ParserFactory::PREFER_PHP7);
      $traverser = new NodeTraverser;
      $traverser->addVisitor(new ParentConnectingVisitor());
      $ast = $parser->parse($this->loadedFile['contents']);
      $ast = $traverser->traverse($ast);
      $context = $this->getDotAssignments($ast);

      foreach ($context['assignments'] as $assignment) {
        array_unshift($assignment['dot'], $assignment['var']);
        $dot_string = implode('.', $assignment['dot']);
        if ($dot_string === $variable_name) {
          return $assignment['value'];
        }
      }
    }
    catch (Error $error) {
      echo "Parse error: {$error->getMessage()}\n";
    }

    return NULL;
  }

  private function getDotAssignments($input, array &$context = []): array {
    $context += [
      'pointer' => -1,
      'assignments' => [],
    ];
    $base = [
      'var' => '',
      'dot' => [],
      'value' => '',
    ];
    if (is_array($input)) {
      foreach ($input as $item) {
        $this->getDotAssignments($item, $context);
      }
    }
    elseif ($input instanceof Node\Stmt\Expression) {
      $this->getDotAssignments($input->expr, $context);
    }
    elseif ($input instanceof Node\Expr\Assign) {
      $context['pointer']++;
      $context['assignments'][$context['pointer']] = $base;
      /** @var array $context */
      $context['assignments'][$context['pointer']]['dot'] = [];
      if (isset($input->expr->value)) {
        $context['assignments'][$context['pointer']]['value'] = $input->expr->value;
      }
      $this->getDotAssignments($input->var, $context);
      $this->getDotAssignments($input->expr, $context);
    }
    elseif ($input instanceof Variable) {
      $dot_value = $input->name;
      $context['assignments'][$context['pointer']]['var'] = $dot_value;
    }
    elseif ($input instanceof Node\Expr\ArrayDimFetch) {
      if (isset($input->dim->value)) {
        $dot_value = $input->dim->value;
        array_unshift($context['assignments'][$context['pointer']]['dot'], $dot_value);
      }
      $this->getDotAssignments($input->var, $context);
    }
    elseif ($input instanceof Node\Expr\ArrayItem) {
      if (isset($input->key->value)) {
        $dot_value = $input->key->value;
        $context['assignments'][$context['pointer']]['dot'][] = $dot_value;
      }

      if ($input->value instanceof Node\Scalar && isset($input->value->value)) {
        $context['assignments'][$context['pointer']]['value'] = $input->value->value;
      }
      $this->getDotAssignments($input->value, $context);
    }
    elseif ($input instanceof Node\Expr\Array_) {
      foreach ($input->items as $item) {
        $this->getDotAssignments($item, $context);
      }
    }

    return $context;
  }

}


