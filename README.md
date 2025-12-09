Simple project to allow creating a game n music binary with a custom arm9 payload.

In the `data/` folder are the binaries taken from a game n' music rom dump,
`bare-entrypoint.bin` is the initial loader present in the official binary,
which normally would use datel's decompression function to decompress the arm9,
but it has been patched to jump to whatever function is appended at the end of it,
in our case the target function is a single call to the LZSS swi to decompress the
`arm9.bin` file from the `src` folder (currently that is the loaded arm9 compressed
with lzss)

The generated rom needs to be encrypted with blowfish keys to be flashable