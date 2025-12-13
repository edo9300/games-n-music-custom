OUTPUT_FORMAT("elf32-littlearm")
OUTPUT_ARCH(arm)
ENTRY(startup)
ENTRY(sdRead)
ENTRY(sdWrite)
SECTIONS
{
    .text :
    {
        *(.text.startup);
        *(.text.sdRead);
        *(.text.sdWrite);
        *(.text*);
    }
}