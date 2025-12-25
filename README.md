Simple project to allow creating a game n music binary with a custom arm9 payload.

In the `data/` folder are the binaries taken from a game n' music rom dump and respective
rom metadata.
 - `arm9.bin` is the decompressed arm9 binary present in the original binary.
 - `bare-entrypoint.bin` is the initial loader present in the official binary,
which normally would use datel's decompression function to decompress the arm9,
but it has been patched to jump to whatever function is appended at the end of it.
In our case the target function is a very barebone `loader9.s`.
To fix 3ds compatibility with the generated rom image, a simple `loader7.s` gets loaded to a
supported memory region, and then puts the original arm7 binary to its expected location in ram.
 - `arm7.bin` is the arm7 binary present in the original binary.

`sd_patches` contains a modified gnm sdhc dldi that is adapted to interface with the internals of the GnM firmware.
`nds-miniboot` contains a slightly modified nds miniboot build that supports having a filename passed to it.

## Patches
`loader9.s` takes care of loading the original gnm arm9 binary, stored in our case with LZSS
compression during the build step, it then applies various patches to it:
 - Then the sd related functions are replaced with the custom ones supporting SDHC carts.
 - MBR loading code is patched to support drives formatted on modern systems which are valid drives but
 using an "unkonwn" partition type (still compatible with the og firmware).
 - The nds loader is replaced by nds-miniboot, offering auto dldi patching and argv passing.

## Installing
Download either artifact from [the releases](https://github.com/edo9300/game-n-music-custom/releases/latest)
and flash it to your games n' music with [datel Tool](https://github.com/ApacheThunder/datelTool)
(or you can also launch the .nds directly from a slot 2 flashcart with the games n' music inserted)

## Compiling
A Wonderful toolchain+blocksds setup is required with the following packages installed:
wf-nnpack
blocksds-toolchain (v.1.16.0 or later)

Then run `make` on the root folder, 3 files will be generated:
`GameNMusic2.nds`: Rom containing patched arm7 and arm9 but with no secure area (won't boot if flashed to cart)
`GameNMusic2-enc.nds` and `gnm-backup.bin`: Rom containing the secure area section taken from the original datel dump.