OUTPUT_FORMAT("elf32-littlearm")
OUTPUT_ARCH(arm)
ENTRY(sdWrite)
ENTRY(getData)
SECTIONS
{
    .text 0x020181cc:
    {
        *(.text.sdWrite);
        *(.text*);
        *(.data);
        *(.data_ro);
    }
}