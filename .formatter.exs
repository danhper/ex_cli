locals_without_parens = [
  aliases: 1,
  argument: 2,
  description: 1,
  long_description: 1,
  name: 1,
  option: 2,
  default_command: 1
]

[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  locals_without_parens: locals_without_parens,
  export: [locals_without_parens: locals_without_parens]
]
