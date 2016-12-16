#include <kern/e1000.h>

// LAB 6: Your driver code here
struct e1000_tx_desc tx_desc_buf[TXRING_LEN] __attribute__ ((aligned (16)));
struct e1000_data tx_data_buf[TXRING_LEN];

int e1000_attach(struct pci_func *pcif){
	// enable PCI function
	pci_func_enable(pcif);
	e1000 = mmio_map_region(pcif->reg_base[0], pcif->reg_size[0]);
	init_desc();
	e1000_init();
	cprintf("Device status Register %x\n", e1000[E1000_STATUS]);
	//assert(e1000[E1000_STATUS] == 0x80080783);
	return 0;
}

static void init_desc(){
	// Zero out the whole transmission descriptor queue
	memset(tx_desc_buf, 0, sizeof(struct e1000_tx_desc) * TXRING_LEN);
	int i;
	for (i = 0; i < TXRING_LEN; ++i)
	{
		tx_desc_buf[i].buffer_addr = PADDR(&tx_data_buf[i]);
		tx_desc_buf[i].upper.fields.status = E1000_TXD_STAT_DD;
	}
}

static void e1000_init(){
	
	// Set TDBAL (Transmit Descriptor Base Address) to the above allocated address.
	e1000[E1000_TDBAL] = PADDR(tx_desc_buf);
	e1000[E1000_TDBAH] = 0x0;

	// Set TDLEN (Transmit Descriptor Length). Must be 128 byte aligned.
	e1000[E1000_TDLEN] = TXRING_LEN * sizeof(struct e1000_tx_desc);

	// Write 0 to Transmit Descriptor Head (TDH) and to Transmit Descriptor Tail (TDHT)
	e1000[E1000_TDH] = 0x00000000;
	e1000[E1000_TDT] = 0x00000000;

	// Initialize the Transmit Control Register (TCTL) with the following
	// - set enable bit to 1 (TCTL.EN)
	// - set pad short packets bit to 1 (TCTL.PSP)
	// - set collision threshold to 0x10 (TCTL.CT) ?? See if can be removed
	// - set collision distance to 0x40 (TCTL.COLD)
	e1000[E1000_TCTL] |= E1000_TCTL_EN;
	e1000[E1000_TCTL] |= E1000_TCTL_PSP;
	e1000[E1000_TCTL] |= E1000_TCTL_CT;
	e1000[E1000_TCTL] |= E1000_TCTL_COLD;

	// Initialize the Transmit IPG register. The TIPG is broken up into three:
	// - IPGT, bits 0-9, set to 0xA
	// - IPGR1, bits 19-10, set to 0x8 (2/3 * 0xc)
	// - IPGR2, bits, 19-20, set to 0xc
	e1000[E1000_TIPG] |= (0xA << E1000_TIPG_IPGT);
	e1000[E1000_TIPG] |= (0x8 << E1000_TIPG_IPGR1);
	e1000[E1000_TIPG] |= (0xC << E1000_TIPG_IPGR2);
	
}

int e1000_transmit(uint8_t *addr, size_t length){

	uint32_t tail = e1000[E1000_TDT];
	
	if (length > DATA_SIZE)
		panic("e1000_transmit: size of packet is larger than max allowed data size \n");
		
	struct e1000_tx_desc * tail_desc = &tx_desc_buf[tail];

	if (tail_desc->upper.fields.status != E1000_TXD_STAT_DD)
		return -1;
	
	memmove(&tx_data_buf[tail], addr, length);
	tail_desc->lower.flags.length = length;
	tail_desc->upper.fields.status = 0;
	tail_desc->lower.data |=  (E1000_TXD_CMD_RS | E1000_TXD_CMD_EOP);
	e1000[E1000_TDT] = (tail + 1) % TXRING_LEN;
	return 0;
		
}

