<?php // PHP CS Fixer v2+.
return PhpCsFixer\Config::create()
    ->setRules([
        '@Symfony'                           => true,
        'no_unused_imports'                  => false,
        'standardize_not_equal'              => false,
        'blank_line_before_return'           => false,
        'blank_line_after_opening_tag'       => false,
        'single_blank_line_before_namespace' => false,
        'phpdoc_annotation_without_dot'      => false,
        'hash_to_slash_comment'              => false,
        'no_empty_comment'                   => false,

        // Other rules.

        'binary_operator_spaces' => [
            'align_equals'       => true,
            'align_double_arrow' => true,
        ],
        'no_blank_lines_before_namespace'           => true,
        'no_multiline_whitespace_before_semicolons' => true,

        'phpdoc_order'        => true,
        'phpdoc_no_alias_tag' => ['var' => 'type'],

        // 'array_syntax' => ['syntax' => 'short'],
        // Disabling this to avoid altering PHP <= 5.3 code.
        // You can enable this temporarily to auto-fix PHP 5.4+ code.
     ]);
