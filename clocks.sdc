create_clock -name F14 -period 14.1MHz  [get_ports {F14}]
create_generated_clock -name F14_2 -source [get_ports {F14}] -phase 45 [get_ports {F14_2}]
create_clock -name F28 -period 28.1MHz  [get_ports {F28}]
