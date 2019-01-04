#!/bin/bash
# $1表示需要处理的二进制bin文件
bin_all=$(hexdump -C $1 | head -n8 | awk '{print $2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17}' | tr [a-z] [A-Z])
[ $(echo $bin_all | awk '{print $NR}') = "0D" ] && sff=8436 ; [ $(echo $bin_all | awk '{print $NR}') = "11" ] && sff=8636
clear
hex_to_bin() {
	hex=$((0x$bin))
	bin_b=$(echo "obase=2;$hex" | bc) && bin_b=$(printf "%08d" $bin_b | rev | awk -F "" '{for(a=1;a<=NF;a++){print $a}}')
}
match07() {
	hex_to_bin ; num07=0 ; a=
# $1-第0位 ~ $8-第7位
for bb07 in $bin_b 
do
	case $num07 in
		0) [ $bb07 -eq 1 ] && a="$1" ; num07=$(($num07 + 1)) ;;
		1) [ $bb07 -eq 1 ] && a="$a,$2" ; num07=$(($num07 + 1)) ;;
		2) [ $bb07 -eq 1 ] && a="$a,$3" ; num07=$(($num07 + 1)) ;;
		3) [ $bb07 -eq 1 ] && a="$a,$4" ; num07=$(($num07 + 1)) ;;
		4) [ $bb07 -eq 1 ] && a="$a,$5" ; num07=$(($num07 + 1)) ;;
		5) [ $bb07 -eq 1 ] && a="$a,$6" ; num07=$(($num07 + 1)) ;;
		6) [ $bb07 -eq 1 ] && a="$a,$7" ; num07=$(($num07 + 1)) ;;
		7) [ $bb07 -eq 1 ] && a="$a,$8" ; num07=$(($num07 + 1)) ;;
	esac
done
}
match0701() {
	hex_to_bin ; num07=0 ; a=
# $1-第0位值为0，$2-第0位值为1...$16-第7位值为1
for bb07 in $bin_b 
do
	case $num07 in
		0) [ $bb07 -eq 0 ] && a="$1" ;  [ $bb07 -eq 1 ] && a="$2" ; num07=$(($num07 + 1)) ;;
		1) [ $bb07 -eq 0 ] && a="$a,$3" ;  [ $bb07 -eq 1 ] && a="$a,$4" ; num07=$(($num07 + 1)) ;;
		2) [ $bb07 -eq 0 ] && a="$a,$5" ;  [ $bb07 -eq 1 ] && a="$a,$6" ; num07=$(($num07 + 1)) ;;
		3) [ $bb07 -eq 0 ] && a="$a,$7" ;  [ $bb07 -eq 1 ] && a="$a,$8" ; num07=$(($num07 + 1)) ;;
		4) [ $bb07 -eq 0 ] && a="$a,$9" ;  [ $bb07 -eq 1 ] && a="$a,${10}" ; num07=$(($num07 + 1)) ;;
		5) [ $bb07 -eq 0 ] && a="$a,${11}" ;  [ $bb07 -eq 1 ] && a="$a,${12}" ; num07=$(($num07 + 1)) ;;
		6) [ $bb07 -eq 0 ] && a="$a,${13}" ;  [ $bb07 -eq 1 ] && a="$a,${14}" ; num07=$(($num07 + 1)) ;;
		7) [ $bb07 -eq 0 ] && a="$a,${15}" ;  [ $bb07 -eq 1 ] && a="$a,${16}" ; num07=$(($num07 + 1)) ;;
	esac
done
}
echo -e "\n1-整理排序编码内容 \n2-根据编码内容匹配协议参数 \n"
read -p "请选择功能 ：" main
case $main in
1)
	for bin_a in $bin_all; do echo 0x$bin_a; done
;;
2)
stb=128
#-------------------------------------------------------------------------------------------------
if [ $sff = 8436 ]; then
for bin in $bin_all
do
 case $stb in
 128) 
	[ $bin = "11" ] && c128="QSFP28" ; [ $bin = "0D" ] && c128=QSFP+ ; [ $bin = "03" ] && c128=SFP+ 
	stb=$(($stb + 1)) ;;
 129) 
	hex_to_bin ; num07=0 ; a=
	for b129 in $bin_b
	do
	case $num07 in
		0|1|5) num07=$(($num07 + 1)) ;;
		2) case $b129 in 0) a="No CDR in RX" ;; 1) a="CDR present in RX" ;; esac ; num07=$(($num07 + 1)) ;; 
		3) case $b129 in 0) a="$a,No CDR in TX" ;; 1) a="$a,CDR present in TX" ;; esac ; num07=$(($num07 + 1)) ;; 
		4) case $b129 in 0) a="$a,No CLEI code present in Page 02h" ;; 1) a="$a,CLEI code present in Page 02h" ;; esac ; num07=$(($num07 + 1)) ;; 
		6) t6=$b129 ; num07=$(($num07 + 1)) ;; 
		7) t7="$t6$b129"
		case $t7 in
		00) a="$a,Power Class 1 Module (1.5W max. Power consumption)" ;; 
		01) a="$a,Power Class 2 Module (2.0W max. Power consumption)" ;; 
		10) a="$a,Power Class 3 Module (2.5W max. Power consumption)" ;; 
		11) a="$a,Power Class 4 Module (3.5W max. Power consumption)" ;; 
		esac ; num07=$(($num07 + 1)) ;; 
	esac
	done
	c129="$a" ; stb=$(($stb + 1)) ;;
	130)
	case $bin in
	00) c130="Unknown or unspecified" ;; 01) c130="SC" ;; 02) c130="FC Style 1 copper connector" ;; 03) c130="FC Style 2 copper connector" ;;
	04) c130="BNC/TNC" ;; 05) c130="FC coax headers" ;; 06) c130="Fiberjack" ;; 07) c130="LC" ;; 08) c130="MT-RJ" ;; 09) c130="MU" ;; 
	0A) c130="SG" ;; 0B) c130="Optical Pigtail" ;; 0C) c130="MPO" ;; 20) c130="HSSDC II" ;; 21) c130="Copper pigtail" ;; 22) c130="RJ45" ;;
	23) c130="No separable connector" ;; 
	esac ; stb=$(($stb + 1)) ;;
	131)
	[ $bin != "00" ] && \
	match07 "40G Active Cable (XLPPI)" "40GBASE-LR4" "40GBASE-SR4" "40GBASE-CR4" "10GBASE-SR" "10GBASE-LR" "10GBASE-LRM" "" && c131="$a"
	stb=$(($stb + 1)) ;;
	132)
	[ $bin != "00" ] && \
	match07 "OC 48 short reach" "OC 48, intermediate reach" "OC 48, long reach" "40G OTN (OTU3B/OTU3C)" "" "" "" "" && c132="$a"
	stb=$(($stb + 1)) ;;
	133)
	[ $bin != "00" ] && \
	match07 "" "" "" "" "SAS 3.0 Gbps" "SAS 6.0 Gbps" "" "" && c133="$a"
	stb=$(($stb + 1)) ;;
	134)
	[ $bin != "00" ] && \
	match07 "1000BASE-SX" "1000BASE-LX" "1000BASE-CX" "1000BASE-T" "" "" "" "" && c134="$a"
	stb=$(($stb + 1)) ;;
	135)
	[ $bin != "00" ] && \
	match07 "Electrical inter-enclosure (EL)" "Longwave laser (LC)" "" "Medium (M)" "Long distance (L)" "Intermediate distance (I)" "Short distance (S)" "Very long distance (V)" && c135="$a"
	stb=$(($stb + 1)) ;;
	136)
	[ $bin != "00" ] && \
	match07 "" "" "" "" "Longwave Laser (LL)" "Shortwave laser w OFC (SL)" "Shortwave laser w/o OFC (SN)" "Electrical intra-enclosure" && c136="$a"
	stb=$(($stb + 1)) ;;
	137)
	[ $bin != "00" ] && \
	match07 "Single Mode (SM)" "Multi-mode 50 um (OM3)" "Multi-mode 50 um (M5)" "Multi-mode 62.5 um (M6)" "Video Coax (TV)" "Miniature Coax (MI)" "Shielded Twisted Pair (TP)" "Twin Axial Pair (TW)" && c137="$a"
	stb=$(($stb + 1)) ;;
	138)
	[ $bin != "00" ] && \
	match07 "100 MBps" "" "200 MBps" "" "400 MBps" "1600 MBps (per channel)" "800 MBps" "1200 MBps (per channel)" && c138="$a"
	stb=$(($stb + 1)) ;;
	139)
	case $bin in
	00) c139="Unspecified" ;; 01) c139="8B10B" ;; 02) c139="4B5B" ;; 03) c139="NRZ" ;; 04) c139="SONET Scrambled" ;; 05) c139="64B66B" ;; 06) c139="Manchester" ;;	
	esac ; stb=$(($stb + 1)) ;;
	140)
	case $bin in 67) c140="10300Mb/s" ;; FF) c140="25500Mb/s" ;; esac ; stb=$(($stb + 1)) ;;
	141)
	hex_to_bin ; num07=0 ; a=
	for b141 in $bin_b
	do
		case $num07 in 0) [ $b141 -eq 1 ] ; a="QSFP+ Rate Select Version 1" ; num07=$(($num07 + 1)) ;; esac
	done
	c141="$a" ; stb=$(($stb + 1)) ;;
	142)
	[ $bin != "00" ] && c142="$((0x$bin))km" ; stb=$(($stb + 1)) ;;
	143)
	[ $bin != "00" ] && t143="$((0x$bin))" && c143="$(($t143 * 2))m" ; stb=$(($stb + 1)) ;;
	144)
	[ $bin != "00" ] && c144="$((0x$bin))m" ; stb=$(($stb + 1)) ;;
	145)
	[ $bin != "00" ] && c145="$((0x$bin))m" ; stb=$(($stb + 1)) ;;
	146)
	[ $bin != "00" ] && c146="$((0x$bin))m" ; stb=$(($stb + 1)) ;;	
	147)
	hex_to_bin ; num07=0 ; a=
	for b147 in $bin_b
	do
		case $num07 in
		0) [ $b147 -eq 0 ] && a="Transmitter not tunable" ; [ $b147 -eq 1 ] && a="Transmitter tunable" ; num07=$(($num07 + 1)) ;;
		1) [ $b147 -eq 0 ] && a="$a,Pin detector" ; [ $b147 -eq 1 ] && a="$a,APD detector" ; num07=$(($num07 + 1)) ;;
		2) [ $b147 -eq 0 ] && a="$a,Uncooled transmitter device" ; [ $b147 -eq 1 ] && a="$a,Cooled transmitter" ; num07=$(($num07 + 1)) ;;
		3) [ $b147 -eq 0 ] && a="$a,No wavelength control" ; [ $b147 -eq 1 ] && a="$a,Active wavelength control" ; num07=$(($num07 + 1)) ;;
		4) t4=$b147; num07=$(($num07 + 1)) ;;
		5) t5=$b147; num07=$(($num07 + 1)) ;;
		6) t6=$b147; num07=$(($num07 + 1)) ;;
		7) t7=$b147; t47="$t4$t5$t6$t7"
		case $t47 in
		"0000") a="$a,850 nm VCSEL" ;; "0001") a="$a,1310 nm VCSEL" ;; "0010") a="$a,1550 nm VCSEL" ;; "0011") a="$a,1310 nm FP" ;;
		"0100") a="$a,1310 nm DFB" ;; "0101") a="$a,1550 nm DFB" ;; "0110") a="$a,1310 nm EML" ;; "0111") a="$a,1550 nm EML" ;;
		"1000") a="$a" ;; "1001") a="$a,1490 nm DFB" ;; "1010") a="$a,Copper cable unequalized" ;; "1011") a="$a,Copper cable passive equalized" ;;
		"1100") a="$a,Copper cable, near and far end limiting active equalizers" ;; "1101") a="$a,Copper cable, far end limiting active equalizers" ;;
		"1110") a="$a,Copper cable, near end limiting active equalizers" ;; "1111") a="$a,Copper cable, linear active equalizers" ;;
		esac
		num07=$(($num07 + 1)) ;;
		esac
	done
	c147="$a" ; stb=$(($stb + 1)) ;;
	148|149|150|151|152|153|154|155|156|157|158|159|160|161|162|163)
	stb=$(($stb + 1)) ;;
	164)
	match07 "SDR" "DDR" "QDR" "FDR" "EDR" "HDR" "" ""
	c164="$a"
	stb=$(($stb + 1)) ;;
	165|166|167)
	stb=$(($stb + 1)) ;;
	168|169|170|171|172|173|174|175|176|177|178|179|180|181|182|183)
	stb=$(($stb + 1)) ;;
	184|185)
	stb=$(($stb + 1)) ;;
	186) 
	t186=$bin ; stb=$(($stb + 1)) ;;
	187)
	t1867="$t186$bin" && t1867=$((0x$t1867)) && c187="$(($t1867 / 20))nm" ; c186=$c187 ; stb=$(($stb + 1)) ;;
	188)
	t188=$bin ; stb=$(($stb + 1)) ;;
	189)
	t1889="$t188$bin" && t1889=$((0x$t1889)) && c189="$(($t1889 / 200))nm" ;c188=$c189 ; stb=$(($stb + 1)) ;;
	190)
	c190=$((0x$bin))"℃" ; stb=$(($stb + 1)) ;;	
	191)
	c191="check code" ;	stb=$(($stb + 1)) ;;
	192)
	stb=$(($stb + 1)) ;;
	193)
	[ $bin != "00" ] && match07 "RX output amplitude programming" "" "" "" "" "" "" && c193="$a"
	stb=$(($stb + 1)) ;;
	194)
	[ $bin != "00" ] && \
	match07 "Tx Squelch implemented" "Tx Squelch Disable implemented" "Rx Output Disable capable" "Rx Squelch Disable implemented" "" "" "" "" && c194="$a"
	stb=$(($stb + 1)) ;;
	195)
	[ $bin != "00" ] && \
	match0701 "" "" "" "Tx Loss of Signal implemented" "Tx Squelch implemented to reduce OMA" "Tx Squelch implemented to reduce Pave" "" "Tx_FAULT signal implemented" "" "Tx_DISABLE is implemented and disables the serial output" "no control of the rate select bits in the upper memory table is required" "active control of the select bits in the upper memory table is required to change rates" "" "Memory page 01 provided" "" "Memory page 02 provided" && c195="$a"
	stb=$(($stb + 1)) ;;
	196|197|198|199|200|201|202|203|204|205|206|207|208|209|210|211)
	stb=$(($stb + 1)) ;;
	212|213|214|215|216|217|218|219)
	stb=$(($stb + 1)) ;;
	220)
	[ $bin != "00" ] && \
	match0701 "" "" "" "" "" "" "Received power measurements type:OMA" "Received power measurements type:Average Power" "" "" "" "" "" "" "" "" && c220="$a"
	stb=$(($stb + 1)) ;;
	221)
	[ $bin != "00" ] && \
	match07 "" "" "" "" "the free side device does not support application select and Page 01h does not exist" "the free side device supports rate selection using application select table mechanism" "the module does not support rate selection" "rate selection is implemented using extended rate selection" "" "" "" "" "" "" "" "" && c221="$a"
	stb=$(($stb + 1)) ;;
	222)
	c222="Nominal bit rate, units of 250 Mbps. See Byte 140 description." ; stb=$(($stb + 1)) ;;
	223)
	c223="check code" ; stb=$(($stb + 1)) ;;
	esac
done
#---------------------------------------------------------------------------------------------------------------
elif [ $sff = 8636 ]; then
for bin in $bin_all
do
 case $stb in
 128) 
	[ $bin = "11" ] && c128="QSFP28" ; [ $bin = "0D" ] && c128=QSFP+ ; [ $bin = "03" ] && c128=SFP+ 
	stb=$(($stb + 1)) ;;
 129) 
 	hex_to_bin ; num07=0 ; a=
	for b129 in $bin_b
	do
	case $num07 in
		0) t0=$b129 ; num07=$(($num07 + 1)) ;; 
		1) t1="$t0$b129" ; case $t1 in
		00) a="unused (legacy setting)" ;; 
		01) a="Power Class 5 (4.0 W max.)" ;; 
		10) a="Power Class 6 (4.5 W max.)" ;; 
		11) a="Power Class 7 (5.0 W max.)" ;; esac ; num07=$(($num07 + 1)) ;; 
		2) case $b129 in 0) a="$a,No CDR in RX" ;; 1) a="$a,CDR present in RX" ;; esac ; num07=$(($num07 + 1)) ;; 
		3) case $b129 in 0) a="$a,No CDR in TX" ;; 1) a="$a,CDR present in TX" ;; esac ; num07=$(($num07 + 1)) ;; 
		4) case $b129 in 0) a="$a,No CLEI code present in Page 02h" ;; 1) a="$a,CLEI code present in Page 02h" ;; esac ; num07=$(($num07 + 1)) ;; 
		5) num07=$(($num07 + 1)) ;; 
		6) t6=$b129 ; num07=$(($num07 + 1)) ;; 
		7) t7="$t6$b129" ; case $t7 in
		00) a="$a,Power Class 1 (1.5 W max.)" ;; 
		01) a="$a,Power Class 2 (2.0 W max.)" ;; 
		10) a="$a,Power Class 3 (2.5 W max.)" ;; 
		11) a="$a,Power Class 4 (3.5 W max.)" ;; esac ; num07=$(($num07 + 1)) ;; 
	esac
	done
	c129="$a" ; stb=$(($stb + 1)) ;;
	130)
	case $bin in
	00) c130="Unknown or unspecified" ;; 01) c130="SC" ;; 02) c130="FC Style 1 copper connector" ;; 03) c130="FC Style 2 copper connector" ;;
	04) c130="BNC/TNC" ;; 05) c130="FC coax headers" ;; 06) c130="Fiberjack" ;; 07) c130="LC" ;; 08) c130="MT-RJ" ;; 09) c130="MU" ;; 
	0A) c130="SG" ;; 0B) c130="Optical Pigtail" ;; 0C) c130="MPO" ;; 20) c130="HSSDC II" ;; 21) c130="Copper pigtail" ;; 22) c130="RJ45" ;;
	23) c130="No separable connector" ;; 
	esac ; stb=$(($stb + 1)) ;;
	131)
	[ $bin != "00" ] && \
	match07 "40G Active Cable (XLPPI)" "40GBASE-LR4" "40GBASE-SR4" "40GBASE-CR4" "10GBASE-SR" "10GBASE-LR" "10GBASE-LRM" "Extended" && c131="$a"
	stb=$(($stb + 1)) ;;
	132)
	[ $bin != "00" ] && match07 "OC 48 short reach" "OC 48, intermediate reach" "OC 48, long reach" "" "" "" "" "" && c132="$a"
	stb=$(($stb + 1)) ;;
	133)
	[ $bin != "00" ] && match07 "" "" "" "" "SAS 3.0 Gbps" "SAS 6.0 Gbps" "SAS 12.0 Gbps" "SAS 24.0 Gbps" && c133="$a"
	stb=$(($stb + 1)) ;;
	134)
	[ $bin != "00" ] && match07 "1000BASE-SX" "1000BASE-LX" "1000BASE-CX" "1000BASE-T" "" "" "" "" && c134="$a"
	stb=$(($stb + 1)) ;;
	135)
	[ $bin != "00" ] && \
	match07 "Electrical inter-enclosure (EL)" "Longwave laser (LC)" "" "Medium (M)" "Long distance (L)" "Intermediate distance (I)" "Short distance (S)" "Very long distance (V)" && c135="$a"
	stb=$(($stb + 1)) ;;
	136)
	[ $bin != "00" ] && \
	match07 "" "" "" "" "Longwave Laser (LL)" "Shortwave laser w OFC (SL)" "Shortwave laser w/o OFC (SN)" "Electrical intra-enclosure" && c136="$a"
	stb=$(($stb + 1)) ;;
	137)
	[ $bin != "00" ] && \
	match07 "Single Mode (SM)" "Multi-mode 50 um (OM3)" "Multi-mode 50 um (M5)" "Multi-mode 62.5 um (M6)" "Video Coax (TV)" "Miniature Coax (MI)" "Shielded Twisted Pair (TP)" "Twin Axial Pair (TW)" && c137="$a"
	stb=$(($stb + 1)) ;;
	138)
	[ $bin != "00" ] && \
	match07 "100 MBps" "Extended" "200 MBps" "3200 MBps (per channel)" "400 MBps" "1600 MBps (per channel)" "800 MBps" "1200 MBps (per channel)" && c138="$a"
	stb=$(($stb + 1)) ;;
	139)
	case $bin in
	00) c139="Unspecified" ;; 01) c139="8B10B" ;; 02) c139="4B5B" ;; 03) c139="NRZ" ;; 04) c139="SONET Scrambled" ;; 05) c139="64B66B" ;; 06) c139="Manchester" ;;	
	esac ; stb=$(($stb + 1)) ;;
	140)
	case $bin in 67) c140="10300Mb/s" ;; FF) c140="25500Mb/s" ;; esac ; stb=$(($stb + 1)) ;;
	141)
	hex_to_bin ; num07=0 ; a=
	for b141 in $bin_b
	do
		case $num07 in
		0) t0=$b141 ; num07=$(($num07 + 1)) ;;
		1) t1="$t0$b141"
		case $t1 in "01") a="Rate Select Version 1" ; num07=$(($num07 + 1)) ;; "10") a="Rate Select Version 2" ; num07=$(($num07 + 1)) ;; esac ;;
		esac
	done
	c141="$a" ; stb=$(($stb + 1)) ;;
	142)
	[ $bin != "00" ] && c142="$((0x$bin))km" ; stb=$(($stb + 1)) ;;
	143)
	[ $bin != "00" ] && t143="$((0x$bin))" && c143="$(($t143 * 2))m" ; stb=$(($stb + 1)) ;;
	144)
	[ $bin != "00" ] && c144="$((0x$bin))m" ; stb=$(($stb + 1)) ;;
	145)
	[ $bin != "00" ] && c145="$((0x$bin))m" ; stb=$(($stb + 1)) ;;
	146)
	[ $bin != "00" ] && c146="$((0x$bin))m" ; stb=$(($stb + 1)) ;;	
	147)
	hex_to_bin ; num07=0 ; a=
	for b147 in $bin_b
	do
		case $num07 in
		0) [ $b147 -eq 0 ] && a="Transmitter not tunable" ; [ $b147 -eq 1 ] && a="Transmitter tunable" ; num07=$(($num07 + 1)) ;;
		1) [ $b147 -eq 0 ] && a="$a,Pin detector" ; [ $b147 -eq 1 ] && a="$a,APD detector" ; num07=$(($num07 + 1)) ;;
		2) [ $b147 -eq 0 ] && a="$a,Uncooled transmitter device" ; [ $b147 -eq 1 ] && a="$a,Cooled transmitter" ; num07=$(($num07 + 1)) ;;
		3) [ $b147 -eq 0 ] && a="$a,No wavelength control" ; [ $b147 -eq 1 ] && a="$a,Active wavelength control" ; num07=$(($num07 + 1)) ;;
		4) t4=$b147; num07=$(($num07 + 1)) ;;
		5) t5=$b147; num07=$(($num07 + 1)) ;;
		6) t6=$b147; num07=$(($num07 + 1)) ;;
		7) t7=$b147; t47="$t4$t5$t6$t7"
		case $t47 in
		"0000") a="$a,850 nm VCSEL" ;; "0001") a="$a,1310 nm VCSEL" ;; "0010") a="$a,1550 nm VCSEL" ;; "0011") a="$a,1310 nm FP" ;;
		"0100") a="$a,1310 nm DFB" ;; "0101") a="$a,1550 nm DFB" ;; "0110") a="$a,1310 nm EML" ;; "0111") a="$a,1550 nm EML" ;;
		"1000") a="$a" ;; "1001") a="$a,1490 nm DFB" ;; "1010") a="$a,Copper cable unequalized" ;; "1011") a="$a,Copper cable passive equalized" ;;
		"1100") a="$a,Copper cable, near and far end limiting active equalizers" ;; "1101") a="$a,Copper cable, far end limiting active equalizers" ;;
		"1110") a="$a,Copper cable, near end limiting active equalizers" ;; "1111") a="$a,Copper cable, linear active equalizers" ;;
		esac
		num07=$(($num07 + 1)) ;;
		esac
	done
	c147="$a" ; stb=$(($stb + 1)) ;;
	148|149|150|151|152|153|154|155|156|157|158|159|160|161|162|163)
	stb=$(($stb + 1)) ;;
	164)
	[ $bin != "00" ] && match07 "SDR" "DDR" "QDR" "FDR" "EDR" "HDR" "" "" && c164="$a"
	stb=$(($stb + 1)) ;;
	165|166|167)
	stb=$(($stb + 1)) ;;
	168|169|170|171|172|173|174|175|176|177|178|179|180|181|182|183)
	stb=$(($stb + 1)) ;;
	184|185)
	stb=$(($stb + 1)) ;;
	186) 
	t186=$bin ; stb=$(($stb + 1)) ;;
	187)
	t1867="$t186$bin" && t1867=$((0x$t1867)) && c187="$(($t1867 / 20))nm" ; c186=$c187 ; stb=$(($stb + 1)) ;;
	188)
	t188=$bin ; stb=$(($stb + 1)) ;;
	189)
	t1889="$t188$bin" && t1889=$((0x$t1889)) && c189="$(($t1889 / 200))nm" ;c188=$c189 ; stb=$(($stb + 1)) ;;
	190)
	c190=$((0x$bin))"℃" ; stb=$(($stb + 1)) ;;	
	191)
	c191="check code" ;	stb=$(($stb + 1)) ;;
	192)
	stb=$(($stb + 1)) ;;
	193)
	[ $bin != "00" ] && \
	match0701 "" "RX Output Amplitude Fixed Programmable Settings" "" "RX Output Emphasis Fixed Programmable Settings" "" "TX Input Equalization Fixed Programmable Settings" "" "TX Input Equalization Auto Adaptive Capable" "" "Tx Input Adaptive Equalizer Freeze Capable" "" "" "" "" "" "" && c193="$a"
	stb=$(($stb + 1)) ;;
	194)
	[ $bin != "00" ] && \
	match0701 "" "Tx Squelch implemented" "" "Tx Squelch Disable implemented" "" "Rx Output Disable capable" "" "Rx Squelch Disable implemented" "" "Rx CDR Loss of Lock (LOL) Flag implemented" "" "Tx CDR Loss of Lock (LOL) Flag implemented" "" "RX CDR On/Off Control implemented" "" "TX CDR On/Off Control implemented" && c194="$a"
	stb=$(($stb + 1)) ;;
	195)
	[ $bin != "00" ] && \
	match0701 "" "Pages 20-21h implemented" "" "Tx Loss of Signal implemented" "Tx Squelch implemented to reduce Pave" "Tx Squelch implemented to reduce OMA" "" "Tx_FAULT signal implemented" "" "" "" "Rate select is implemented as defined in 6.2.7" "" "Memory Page 01h provided" "" "Memory Page 02 provided" && c195="$a"
	stb=$(($stb + 1)) ;;
	196|197|198|199|200|201|202|203|204|205|206|207|208|209|210|211)
	stb=$(($stb + 1)) ;;
	212|213|214|215|216|217|218|219)
	stb=$(($stb + 1)) ;;
	220)
	[ $bin != "00" ] && \
	match0701 "" "" "" "" "" "Transmitter power measurement Supported" "Received power measurements type:OMA" "Received power measurements type:Average Power" "" "Supply voltage monitoring implemented" "" "Temperature monitoring implemented" "" "" "" "" && c220="$a"
	stb=$(($stb + 1)) ;;
	221)
	[ $bin != "00" ] && \
	match07 "" "" "TC readiness flag not implemented" "TC readiness flag is implemented" "the free side device does not support application select and Page 01h does not exist" "the free side device supports rate selection using application select table mechanism" "the free side device does not support rate selection" "rate selection is implemented using extended rate selection" "the initialization complete flag is either not implemented or if implemented has a response time less than t_init, max as specified for the module" "the initialization complete flag at Byte 6 bit 0 is implemented independent of t_init" "" "" "" "" "" "" && c221="$a"
	stb=$(($stb + 1)) ;;
	222)
	c222="Nominal bit rate, units of 250 Mbps. See Byte 140 description." ; stb=$(($stb + 1)) ;;
	223)
	c223="check code" ; stb=$(($stb + 1)) ;;
	esac
done
fi
echo -e "\n--------------------------编码内容匹配对应的 SFF$sff 协议信息--------------------------\n"
echo -e "${c128:-null}\n${c129:-null}\n${c130:-null}\n${c131:-null}\n${c132:-null}\n${c133:-null}\n${c134:-null}\n${c135:-null}\n${c136:-null}\n${c137:-null}\n${c138:-null}\n${c139:-null}\n${c140:-null}\n${c141:-null}\n${c142:-null}\n${c143:-null}"
echo -e "${c144:-null}\n${c145:-null}\n${c146:-null}\n${c147:-null}\n${c148:-null}\n${c149:-null}\n${c150:-null}\n${c151:-null}\n${c152:-null}\n${c153:-null}\n${c154:-null}\n${c155:-null}\n${c156:-null}\n${c157:-null}\n${c158:-null}\n${c159:-null}"
echo -e "${c160:-null}\n${c161:-null}\n${c162:-null}\n${c163:-null}\n${c164:-null}\n${c165:-null}\n${c166:-null}\n${c167:-null}\n${c168:-null}\n${c169:-null}\n${c170:-null}\n${c171:-null}\n${c172:-null}\n${c173:-null}\n${c174:-null}\n${c175:-null}"
echo -e "${c176:-null}\n${c177:-null}\n${c178:-null}\n${c179:-null}\n${c180:-null}\n${c181:-null}\n${c182:-null}\n${c183:-null}\n${c184:-null}\n${c185:-null}\n${c186:-null}\n${c187:-null}\n${c188:-null}\n${c189:-null}\n${c190:-null}\n${c191:-null}"                                                       
echo -e "${c192:-null}\n${c193:-null}\n${c194:-null}\n${c195:-null}\n${c196:-null}\n${c197:-null}\n${c198:-null}\n${c199:-null}\n${c200:-null}\n${c201:-null}\n${c202:-null}\n${c203:-null}\n${c204:-null}\n${c205:-null}\n${c206:-null}\n${c207:-null}"
echo -e "${c208:-null}\n${c209:-null}\n${c210:-null}\n${c211:-null}\n${c212:-null}\n${c213:-null}\n${c214:-null}\n${c215:-null}\n${c216:-null}\n${c217:-null}\n${c218:-null}\n${c219:-null}\n${c220:-null}\n${c221:-null}\n${c222:-null}\n${c223:-null}\n"
;;
esac
