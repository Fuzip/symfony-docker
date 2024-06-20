<?php

use PhpCsFixer\Config;
use PhpCsFixer\Finder;
use PhpCsFixer\Runner\Parallel\ParallelConfigFactory;

return (new Config())
    ->setFinder(
        (new Finder())::create()
        ->in(__DIR__)
        ->exclude(['bin', 'config', 'public', 'templates', 'var', 'vendor'])
    )
    ->setLineEnding(PHP_EOL)
    ->setParallelConfig(ParallelConfigFactory::detect())
    ->setRiskyAllowed(true)
    ->setRules([
        '@Symfony' => true,
        'align_multiline_comment' => true,
        'blank_line_before_statement' => [
            'statements' => [
                'return',
                'throw',
            ],
        ],
        'concat_space' => [
            'spacing' => 'one',
        ],
        'no_extra_blank_lines' => [
            'tokens' => [
                'break',
                'continue',
                'curly_brace_block',
                'extra',
                'parenthesis_brace_block',
                'return',
                'square_brace_block',
                'throw',
                'use',
            ],
        ],
        'no_useless_else' => true,
        'no_useless_return' => true,
        'ordered_imports' => true,
        'phpdoc_order' => true,
        'no_superfluous_phpdoc_tags' => true,
        'phpdoc_var_without_name' => false,
        'single_line_throw' => false,
    ])
;
