# Pomo-Elver

A basic migrations library for use with the [Postmodern](https://github.com/marijnh/Postmodern) PostgreSQL programming interface for Common Lisp. There are already several other good migration libraries for Common Lisp, however I decided to write my own as a learning exercise. 

## Usage

First, using a top-level connection or Postmodern's `with-connection` macro, run `initial-migration`. Then you can define migrations anywhere in your package with `defmigration`. Examples to follow when I get time to write them.

## Installation

As usual for CL projects: clone this repo into `~/common-lisp/` or `~/quicklisp/local-projects/` and load either in the REPL or in a source file with `(ql:quickload :pomo-elver)`.

## Author

* Isaac Stead (isaac.stead@protonmail.com)

## Copyright

Copyright (c) 2020 Isaac Stead (isaac.stead@protonmail.com)

## License

Licensed under the GPL License.
