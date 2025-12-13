 #define ARM9
 #include <nds/ndstypes.h>
 #include <nds/memory.h>
 #include <nds/card.h>
 #include <stddef.h>

#define BYTES_PER_SECTOR 512

#define SD_COMMAND_TIMEOUT 0xFFF
#define SD_WRITE_TIMEOUT 0xFFFF
static const u32 CARD_CR2_SETTINGS = (CARD_ACTIVATE | CARD_nRESET | CARD_SEC_CMD | CARD_DELAY2(0x3F) | CARD_SEC_EN | CARD_SEC_DAT);

#define READ_SINGLE_BLOCK 17
#define WRITE_SINGLE_BLOCK 24
#define SD_WRITE_OK 0x05

#define SPI_START 0xCC
#define SPI_STOP 0xC8

static inline void ndsarSendNtrCommand (const u8 cmd[8], u32 romctrl)
{
    REG_AUXSPICNT = CARD_ENABLE;

    REG_CARD_COMMAND[0] = cmd[0];
    REG_CARD_COMMAND[1] = cmd[1];
    REG_CARD_COMMAND[2] = cmd[2];
    REG_CARD_COMMAND[3] = cmd[3];
    REG_CARD_COMMAND[4] = cmd[4];
    REG_CARD_COMMAND[5] = cmd[5];
    REG_CARD_COMMAND[6] = cmd[6];
    REG_CARD_COMMAND[7] = cmd[7];
    REG_ROMCTRL = romctrl;
    
    while (REG_ROMCTRL & CARD_BUSY);
}

static inline void ndsarNtrF2 (u32 param1, u8 param2)
{
    u8 cmd[8] = {0xF2, param1 >> 24, param1 >> 16, param1 >> 8,
                 param1 & 0xFF, param2, 0x00, 0x00};
    
    ndsarSendNtrCommand(cmd, CARD_CR2_SETTINGS);
}

static inline u8 transferSpiByte (u8 send)
{
	REG_AUXSPIDATA = send;
	while (REG_AUXSPICNT & CARD_SPI_BUSY);
	return REG_AUXSPIDATA;
}

static inline u8 getSpiByte (void) 
{
	REG_AUXSPIDATA = 0xFF;
	while (REG_AUXSPICNT & CARD_SPI_BUSY);
	return REG_AUXSPIDATA;
}


static inline void initSpi (u8 cmd)
{
    ndsarNtrF2(0, cmd);

	REG_AUXSPICNT = CARD_ENABLE | CARD_SPI_ENABLE | CARD_SPI_HOLD;
	if (cmd == SPI_STOP)transferSpiByte(0xFF);
}

static inline u8 getSpiByteTimeout() {
    int timeout = SD_COMMAND_TIMEOUT;
    u8 r1;
    do
    {
        r1 = getSpiByte();
    }
    while (r1 == 0xFF && --timeout > 0);
	return r1;
}

static inline u8 sendCommandLen (u8 cmdId, u32 arg, void* buff, int len)
{
    u8 cmd[6];

    // Build a SPI SD command to be sent as-is.
    cmd[0] = 0x40 | (cmdId & 0x3f);
    cmd[1] = arg >> 24;
    cmd[2] = arg >> 16;
    cmd[3] = arg >>  8;
    cmd[4] = arg >>  0;
    cmd[5] = (len > 1) ? 0x86 : 0x95; // CRC is mostly ignored in SPI mode.
									  // Because the first CMD0 is not exactly in SPI mode,
									  // this is the valid CRC for CMD8 with 0x1AA argument.

    for(int i = 0; i < sizeof(cmd); i++)
        transferSpiByte(cmd[i]);

    u8 r1 = getSpiByteTimeout();
	
	u8* buff_u8 = (u8*)buff;
	
	for(int i = 0; i < (len - 1); ++i) {
		buff_u8[i] = getSpiByte();
	}

    return r1;
}

static inline u8 sendCommand(u8 cmdId, u32 arg) {
	return sendCommandLen(cmdId, arg, NULL, 1);
}

static u8 ndsarSdcardCommandSendLen (u8 cmdId, u32 arg, void* buff, int len)
{
    initSpi(SPI_START);
    u8 r1 = sendCommandLen(cmdId, arg, buff, len);
	
    initSpi(SPI_STOP);

    return r1;
}

static u8 ndsarSdcardCommandSend (u8 cmdId, u32 arg)
{
	return ndsarSdcardCommandSendLen(cmdId, arg, NULL, 1);
}

#define GLOBAL_SD_BUFFER (uint8_t*)0x2065BCC

static bool readSector (u32 sector, u8* dest)
{
	volatile u32 temp;
	initSpi(SPI_START);
	
	bool isSdhc = *GLOBAL_SD_BUFFER != 0;
	
	if (sendCommand (READ_SINGLE_BLOCK, sector * (BYTES_PER_SECTOR - (511 * isSdhc))) != 0x00) {
		initSpi(SPI_STOP);
		return false;
	}

	// Wait for data start token
	u8 spiByte = getSpiByteTimeout();

	if (spiByte != 0xFE) {
		initSpi(SPI_STOP);
		return false;
	}
	
	for (int i = BYTES_PER_SECTOR; i > 0; i--) {
		*dest++ = getSpiByte();
	}

	
	temp = getSpiByte();
	temp = getSpiByte();
	
	initSpi(SPI_STOP);
	return true;
}

static bool writeSector (u32 sector, u8* src)
{
	initSpi(SPI_START);
	
	bool isSdhc = *GLOBAL_SD_BUFFER != 0;

	if (sendCommand (WRITE_SINGLE_BLOCK, sector * (BYTES_PER_SECTOR - (511 * isSdhc))) != 0) {
		initSpi(SPI_STOP);
		return false;
	}
	
	// Send start token
	transferSpiByte(0xFE);
	
	// Send data
	for (int i = BYTES_PER_SECTOR; i > 0; i--) {
		REG_AUXSPIDATA = *src++;
		while (REG_AUXSPICNT & CARD_SPI_BUSY);
	}

	// Send fake CRC
	transferSpiByte(0xFF);
	transferSpiByte(0xFF);
	
	// Get data response
	if ((getSpiByte() & 0x0F) != SD_WRITE_OK) {
		initSpi(SPI_STOP);
		return false;
	}
	
	// Wait for card to write data
	int timeout = SD_WRITE_TIMEOUT;
	while (getSpiByte() == 0 && --timeout > 0);
	
	initSpi(SPI_STOP);
	
	if (timeout == 0) {
		return false;
	}
	
	return true;
}

/*-----------------------------------------------------------------
startUp
Initialize the interface, geting it into an idle, ready state
returns true if successful, otherwise returns false
-----------------------------------------------------------------*/
#define MAX_STARTUP_TRIES 5000

#define CONTROL_VARIABLE *(uint32_t*)0x2062BE0
#define MUTEX_ADDR (void*)0x27FF000

typedef int(*volatile acquire_mutex_t)(void*, int);
typedef int(*volatile release_mutex_t)(void*, int);

#define acquire_mutex(a,b) (*(acquire_mutex_t)0x0201fe68)(a, b)
#define release_mutex(a,b) (*(release_mutex_t)0x0201fe9c)(a, b)

// #define REG_EXMEMCNT    (*(vu16 *)0x04000204)
// #define EXMEMCNT_CARD_ARM7                  BIT(11)
// #define ARM7_OWNS_CARD                      EXMEMCNT_CARD_ARM7

// static inline void sysSetCardOwner(bool arm9)
// {
    // REG_EXMEMCNT = (REG_EXMEMCNT & ~ARM7_OWNS_CARD) | (arm9 ? 0 : ARM7_OWNS_CARD);
// }
static bool ndsarSdcardInitGnm (void)
{
	bool isv2 = false;
    for (int i = 0; i < 0x100; i++)
	{
        ndsarNtrF2(0x7FFFFFFF | ((i & 1) << 31), 0x00);
	}
    
	ndsarNtrF2(0, SPI_STOP);

    // Send CMD0.
    u8 r1 = ndsarSdcardCommandSend(0, 0);
    if (r1 != 0x01) // Idle State.
    {
        // CMD 0 failed.
        return false;
    }
	
	u32 r7_answer;
	
    r1 = ndsarSdcardCommandSendLen(8, 0x1AA, &r7_answer, 5);
	
	u32 acmd41_arg = 0;
	
	if(r1 == 0x1 && r7_answer == 0xAA010000) {
		isv2 = true;
		acmd41_arg |= (1<<30); // Set HCS bit,Supports SDHC
	}
	
	for(int i = 0; i < MAX_STARTUP_TRIES; ++i) {
		// Send ACMD41.
		ndsarSdcardCommandSend(55, 0);
		r1 = ndsarSdcardCommandSend(41, acmd41_arg);
		if(r1 == 0) {
			break;
		}
	}
	if(r1 != 0) {
		return false;
	}
	
	if(isv2) {
		u32 r2_answer;
		r1 = ndsarSdcardCommandSendLen(58, 0, &r2_answer, 5);
		*GLOBAL_SD_BUFFER = (r2_answer & 0x40) != 0;
	}
	ndsarSdcardCommandSend(16, 0x200);
	
	return true;
}

#ifdef STARTUP

bool startup(void) {
	while (acquire_mutex(MUTEX_ADDR,2) != 0);
	sysSetCardOwner(true);
	CONTROL_VARIABLE = 1;
	
	bool res = ndsarSdcardInitGnm();
	
	CONTROL_VARIABLE = 0;
	sysSetCardOwner(false);
	release_mutex(MUTEX_ADDR,2);
	return res;
}

#endif

#ifdef SDREAD

bool sdRead (u32 sector, u8* dest)
{
	while (acquire_mutex(MUTEX_ADDR,2) != 0);
	sysSetCardOwner(true);

	bool res = readSector(sector, dest);

	sysSetCardOwner(false);
	release_mutex(MUTEX_ADDR,2);
	return res;
}

#endif


#ifdef SDWRITE

bool sdWrite (u32 sector, u8* src)
{
	while (acquire_mutex(MUTEX_ADDR,2) != 0);
	sysSetCardOwner(true);

	bool res = writeSector(sector, src);

	sysSetCardOwner(false);
	release_mutex(MUTEX_ADDR,2);
	return res;
}

#endif