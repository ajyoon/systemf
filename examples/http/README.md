# a (slightly) functional HTTP server implemented in systemf

![served webpage screenshot](screenshots/index_preview.png?raw=true "index.html")

This server can handle `GET` requests for files relative to the server's
working directory. It does this through basic low-level socket operations
and some extremely hacky byte manipulation. Because `systemf` doesn't have
any way to properly create C `struct`s, we have to do things like manually
build up structs byte-by-byte, passing the series of brainfuck cells in
memory directly to the kernel.

## Serving

```sh
# If you haven't built the interpreter yet
http$ cd ../../
systemf$ make
# Serve from http working directory
systemf$ cd examples/http/
http$ ../../bin/systemf server.bf
```

The server will listen on `localhost:4000`.
Go to `localhost:4000/index.html` to see the site in action!

It's, uh, pretty insecure. Don't try this in the wild.

For more details about the interpreter and its rules, check out
the [main project readme](https://github.com/ajyoon/systemf).
