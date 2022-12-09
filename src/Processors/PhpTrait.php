<?php

namespace AKlump\LiveDevPorter\Processors;

use PhpParser\Error;
use PhpParser\Node;
use PhpParser\Node\Expr\Variable;
use PhpParser\NodeTraverser;
use PhpParser\NodeVisitor\ParentConnectingVisitor;
use PhpParser\ParserFactory;

trait PhpTrait {

  /**
   * @param string $variable_name
   *   E.g., 'databases.default.default.password'
   * @param string $replace_with
   *
   * @return void
   */
  public function phpReplaceValue(string $variable_name, string $replace_with = '') {
    $this->validateFileIsLoaded();
    if (empty($this->loadedFile['contents'])) {
      return;
    }
    $value_to_replace = $this->getValueByVariableDeclaration($variable_name);
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
      $context = $this->getDotAssignment($ast);
      array_unshift($context['dot'], $context['var']);
      $dot_string = implode('.', $context['dot']);
      if ($dot_string === $variable_name) {
        return $context['value'];
      }
    }
    catch (Error $error) {
      echo "Parse error: {$error->getMessage()}\n";
    }

    return NULL;
  }

  private function getDotAssignment($input, array &$context = []): array {
    $context += [
      'var' => '',
      'dot' => '',
      'value' => '',
    ];
    if (is_array($input)) {
      foreach ($input as $item) {
        $this->getDotAssignment($item, $context);
      }
    }
    elseif ($input instanceof Node\Stmt\Expression) {
      $this->getDotAssignment($input->expr, $context);
    }
    elseif ($input instanceof Node\Expr\Assign) {
      /** @var array $context */
      $context['dot'] = [];
      if (isset($input->expr->value)) {
        $context['value'] = $input->expr->value;
      }
      $this->getDotAssignment($input->var, $context);
      $this->getDotAssignment($input->expr, $context);
    }
    elseif ($input instanceof Variable) {
      $dot_value = $input->name;
      $context['var'] = $dot_value;
    }
    elseif ($input instanceof Node\Expr\ArrayDimFetch) {
      if (isset($input->dim->value)) {
        $dot_value = $input->dim->value;
        array_unshift($context['dot'], $dot_value);
      }
      $this->getDotAssignment($input->var, $context);
    }
    elseif ($input instanceof Node\Expr\ArrayItem) {
      if (isset($input->key->value)) {
        $dot_value = $input->key->value;
        $context['dot'][] = $dot_value;
      }

      if ($input->value instanceof Node\Scalar && isset($input->value->value)) {
        $context['value'] = $input->value->value;
      }
      $this->getDotAssignment($input->value, $context);
    }
    elseif ($input instanceof Node\Expr\Array_) {
      foreach ($input->items as $item) {
        $this->getDotAssignment($item, $context);
      }
    }

    return $context;
  }

}


