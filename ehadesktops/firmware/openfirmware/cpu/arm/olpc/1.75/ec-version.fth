\ The EC microcode
macro: EC_PLATFORM cl2
macro: EC_VERSION 4_1_0_01

\ Alternate command for getting EC microcode, for testing new versions.
\ Temporarily uncomment the line and modify the path as necessary
\ macro: GET_EC cp ~rsmith/olpc/ec/ec-code15/image/ecimage.bin ec.img
\ macro: GET_EC wget -q http://dev.laptop.org/pub/ec/ec_test.img -O ec.img
\ macro: GET_EC cp no_event.bin ec.img
