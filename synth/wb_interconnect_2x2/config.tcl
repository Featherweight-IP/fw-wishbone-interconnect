set script_dir [file dirname [file normalize [info script]]]

#set ::env(DESIGN_NAME) wb_interconnect_2x2
#set ::env(FP_PIN_ORDER_CFG) $script_dir/pin_order.cfg

set ::env(CLOCK_PORT) "clock"
set ::env(CLOCK_PERIOD) "7"

set ::env(FP_SIZING) absolute
set ::env(DIE_AREA) "0 0 700 700"
set ::env(PL_TARGET_DENSITY) 0.4
set ::env(PL_SKIP_INITIAL_PLACEMENT) 1


