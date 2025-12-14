OUTPUT_FORMAT("elf32-littlearm")
OUTPUT_ARCH(arm)
ENTRY(sdRead)
SECTIONS
{
    .text 0x020186ec:
    {
        *(.text.sdRead);
        *(.text*);
    }
}