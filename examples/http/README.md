# a (slightly) functional HTTP server implemented in systemf

To run:


This is a slightly functional HTTP server implemented in
[systemf](https://github.com/ajyoon/systemf), an extension of
the esoteric [brainfuck](https://esolangs.org/wiki/brainfuck)
programming language which provides program access to Linux syscalls via
an additional language character `%`.

The server can handle `GET` requests for files relative to the server's
working directory. It does this through basic low-level socket operations
and some extremely hacky byte manipulation. Because `systemf` doesn't have
any way to properly create C `struct`s, we have to do things like manually
build up structs byte-by-byte, passing the series of brainfuck cells in
memory directly to the kernel.

Building the interpreter:

The interpreter is written in NASM x86-64 assembly. You'll need NASM to build, and if your architecture is not x86-64 you will need to use an emulator or similar solution. Otherwise, it's as easy as:

```sh
http$ cd ../../
systemf$ make [build || debug || clean]
```

To run:

```sh
systemf$ cd examples/http/
http$ ../../bin/systemf server.bf
```

The server will listen on `localhost:4000`.
Go to `localhost:4000/index.html` to see the site in action!

It's, uh, pretty insecure. Don't try this in the wild.

For more details about the interpreter and its rules, check out
the [main project readme](https://github.com/ajyoon/systemf).
