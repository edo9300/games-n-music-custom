OUTPUT_FORMAT("elf32-littlearm")
OUTPUT_ARCH(arm)
ENTRY(startup)
SECTIONS
{
    .text 0x02018b18:
    {
        *(.text.startup);
        *(.text*);
    }
}