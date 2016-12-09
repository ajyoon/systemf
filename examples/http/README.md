# a (slightly) functional HTTP server implemented in systemf

<a href='https://www.recurse.com' title='Made with love at the Recurse Center'><img src='https://cloud.githubusercontent.com/assets/2883345/11325206/336ea5f4-9150-11e5-9e90-d86ad31993d8.png' height='20px'/></a>


brainfuck is awesome, but per spec it's only able to interact with the real world via
STDIN and STDOUT.

By extending the language with a special character `%` which executes a syscall, we can
do a whole lot more with it while having all the "fun" of working in the language.
This lets us do lots of cool things like
write an HTTP server in brainfuck:

![served webpage screenshot](screenshots/index_preview.png?raw=true "index.html")

The server can handle `GET` requests for files relative to the server's
working directory. It does this through basic low-level socket operations
and some extremely hacky byte manipulation. Because `systemf` doesn't have
any way to properly create C `struct`s, we have to do things like manually
build up structs byte-by-byte, passing the series of brainfuck cells in
memory directly to the kernel.

## Building the interpreter:

The interpreter is written in NASM x86-64 assembly. You'll need NASM to build, and if your architecture is not x86-64 you will need to use an emulator or similar solution. Otherwise, it's as easy as:

```sh
http$ cd ../../
systemf$ make [build || debug || clean]
```

## Serving

```sh
systemf$ cd examples/http/
http$ ../../bin/systemf server.bf
```

The server will listen on `localhost:4000`.
Go to `localhost:4000/index.html` to see the site in action!

It's, uh, pretty insecure. Don't try this in the wild.

For more details about the interpreter and its rules, check out
the [main project readme](https://github.com/ajyoon/systemf).
