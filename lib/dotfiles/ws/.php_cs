<?php
return Symfony\CS\Config\Config::create()
    ->level(Symfony\CS\FixerInterface::SYMFONY_LEVEL)
    ->fixers([
        '-return',
        '-standardize_not_equal',
        '-blankline_after_open_tag',
        '-single_blank_line_before_namespace',

         'align_double_arrow',
         'align_equals',

         'newline_after_open_tag',
         'no_blank_lines_before_namespace',
         'multiline_spaces_before_semicolon',

         'ordered_use',
         'phpdoc_order',
         'phpdoc_var_to_type',

         # 'short_array_syntax',

         'strict',
         'strict_param',
     ]);
