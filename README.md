# soda-mode

## Description

**soda-mode** is an Emacs major mode for working with `soda` files.

An example of the soda file format:

```
[group] {
    field_name = "Value";
}

[group_two] {
    [nested_group] {
        field = "Value";
        raw_field = [[
            Some text goes here
        ]];
    }
}
```

This mode supports:

  - Highlighting group names, strings and comments
  - Indentation of groups and nested groups
