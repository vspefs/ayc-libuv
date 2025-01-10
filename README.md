I build libuv with Zig build system. You fetch it and use it in your Zig build system.

Sanitizers not usable. I'm lazy and I'm sorry. Should fix that later.

Should be working on Linux and Windows.
Take care of the platform-specific macros yourself. Like `_GNU_SOURCE` on Linux.

As you could possibly guess, I mean to get this into [All Your Codebase](https://github.com/allyourcodebase/). But I should really provide support for all available platforms first before try to get this to anywhere else.