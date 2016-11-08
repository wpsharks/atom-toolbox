<?php
return Symfony\CS\Config\Config::create()
    ->level(Symfony\CS\FixerInterface::SYMFONY_LEVEL)
    ->fixers([
        '-return',
        '-empty_return',
        '-standardize_not_equal',
        '-blankline_after_open_tag',
        '-single_blank_line_before_namespace',
        '-unused_use',

         'align_double_arrow',
         'align_equals',

         'newline_after_open_tag',
         'no_blank_lines_before_namespace',
         'multiline_spaces_before_semicolon',

         'phpdoc_order',
         'phpdoc_var_to_type',
         '-phpdoc_annotation_without_dot',

         '-no_empty_comment',
         '-hash_to_slash_comment',

         // 'short_array_syntax',
         // Disabling this to avoid altering PHP <= 5.3 code.
         // You can enable this temporarily to auto-fix PHP 5.4+ code.

         'strict',
         'strict_param',
     ]);
