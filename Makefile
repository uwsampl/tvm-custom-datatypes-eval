build-datatypes:
					$(MAKE) -C datatypes/universal-wrapper
					$(MAKE) -C datatypes/bfloat16
					$(MAKE) -C datatypes/nop-type
					$(MAKE) -C datatypes/float32
					$(MAKE) -C datatypes/libposit
					$(MAKE) -C datatypes/biovault_bfloat16
