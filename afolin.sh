#!/bin/bash

#
#	ATTENTION! PRE-CAUTION
#
#	Please don't run this script as sh $0.. you'll get an error message
#	if you do so.. you must execute this script as a bash script, and
#	give executable right for it using chmod +x $0, where $0 is the 
#	name of this script.. 
#
#	The correct way to execute: ./$0 ...
#
#	By Tamas Bogdan <tamas.bogdan@hp.com>
#	
#	Version $ver
#

fe_ver=3.6.5
trifline=/opt/triffid/bin/trifline
mtx=`which mtx`
path=/sys/class/pfo/*/paths
ver=/proc/scsi/sg/version
rp=/sys/bus/scsi/drivers/pfo/ctrl
df=/sys/bus/scsi/drivers/pfo/debug_flag

draw_menu() {
clear

if [ -z "`lsmod | grep pfo`" ] || [ -z "`lsmod | grep sgmp`" ] || [ -z "`lsmod | grep stmp`" ]; then
printf "!! Missing AFO driver(s): PFO, SGMP, STMP\n"
else
printf "AFO ver = `cat $ver`, `cat $rp`, `cat $df | head -1`\n"
fi

printf "\nESL G3 Test Tool Front-End $fe_ver\n\n"
PS3='--> '
options=(\
"triffid: single CMDs" \
"triffid: CMD sequences" \
"triffid: move media sequences" \
"triffid: move media only" \
"triffid: ESL non-afo restricted cmds" \
"dd + mt: single CMDs" \
"dd + mt: single CMDs with variable BS" \
"mtx: single cycle move medium" \
"CHO: triffid ~2TB" \
"CHO: dd+mt ~1,5TB" \
"EXCEPTION" \
"discover changer" \
"turn path rotation ON" \
"turn path rotation OFF" \
"release/free up unit" \
"show path status" \
"increase debug verbosity level" \
"turn off debug messages" \
"about" \
"reboot" \
"exit")

select opt in "${options[@]}"
do
	case $opt in
        "triffid: single CMDs")
		tr_single_cmds
        ;;
        "triffid: CMD sequences")
		tr_sequence_cmds
        ;;
        "triffid: move media sequences")
		tr_move
        ;;
        "triffid: move media only")
		tr_move_only
        ;;
        "triffid: ESL non-afo restricted cmds")
        tr_esl
        ;;
        "dd + mt: single CMDs")
        ddmt_single_cmds
		;;
		"dd + mt: single CMDs with variable BS")
        ddmt_single_cmds_var_bs
		;;
		"mtx: single cycle move medium")
		mtx_esl
		;;
		"CHO: triffid ~2TB")
		cho_trifline
		;;
		"CHO: dd+mt ~1,5TB")
		cho_dd
		;;
		"EXCEPTION")
		exception
		;;		
		"discover changer")
		discover_changer
		;;
		"turn path rotation ON")
		path_rotate_on
		;;
		"turn path rotation OFF")
		path_rotate_off
		;;
		"release/free up unit")
		release_unit
		;;
		"show path status")
		show
		;;
		"increase debug verbosity level")
		echo 0xffff > $df
		printf "\nDebug verbosity level increased!\n\n"
		;;
		"turn off debug messages")
		echo 0x0000 > $df
		printf "\nDebug messages turned off on console!\n\n"
		;;
		"about")
		printf "\nESL G3 Test Tool Front-End $fe_ver\n"
		printf "AFO ver = `cat $ver 2>/dev/null`, `cat $rp 2>/dev/null`, `cat $df | head -1 2>/dev/null`\n\n"
		;;
		"reboot")
		re_boot
		;;
        "exit")
	    exit 0
        ;;
        
        *) printf "No such option!\n"
        ;;
    esac
done
}


function tr_single_cmds {
		printf "\nSingle command execution\n\nEnter device file name: "
		read dev
		printf "Enter the number of loops: "
		read loop
		
		if [ -z $dev ] || [ -z $loop ]; then
		printf "You must specify all the parameters!\n"
		sleep 3
		break
		fi
		
		
		for i in `seq 1 $loop`; do
		$trifline -o $dev -f singles.trm -l log
		if [ $? -ne 0 ]; then
		printf "Error in loop #$i ..\n"
		loop=$i		# return with the appropriate failing loop number
		break
		fi
		done
		printf "\n\nPress << ENTER >> to redraw menu.\n\n"
}

function tr_sequence_cmds {
		printf "\nCommand sequence execution\n\nEnter device file name: "
		read dev
		printf "Enter the number of loops: "
		read loop
		
		if [ -z $dev ] || [ -z $loop ]; then
		printf "You must specify all the parameters!\n"
		sleep 3
		break
		fi
		
		
		for i in `seq 1 $loop`; do
		$trifline -o $dev -f sequences.trm
		if [ $? -ne 0 ]; then
		printf "Error in loop #$i ..\n"
		loop=$i		# return with the appropriate failing loop number
		break
		fi
		printf "$i loop complete.\n"
		done
		printf "\n\nPress << ENTER >> to redraw menu.\n\n"
}

function tr_move {
		printf "\nMove cartridges with triffid\n\n"
		tmptrm=`mktemp`
		printf "Enter S1, slot A: "
		read s1a
		printf "Enter S1, slot B: "
		read s1b
		printf "Enter S2, slot A: "
		read s2a
		printf "Enter S2, slot B: "
		read s2b
		printf "Enter device to use: "
		read dev
		printf "Enter number of loops: "
		read loop
		
		if [ -z $dev ] || [ -z $s1a ] || [ -z $s1b ] || [ -z $s2a ] || [ -z $s2b ] || [ -z $loop ]; then
		printf "You must specify all the parameters!\n"
		sleep 3
		break
		fi
		
		
		printf "
		echo (workaround)\n
		stop_on_error(true)\n
		prevent_media_removal (false)\n
		release_unit()\n
		prevent_media_removal (true)\n
		test_unit_ready ()\n
		test_unit_ready ()\n
		reserve_unit ()\n 
		release_unit ()\n
		reserve_unit ()\n 
		release_unit ()\n
		reserve_unit ()\n 
		release_unit ()\n
		reserve_unit ()\n 
		release_unit ()\n
		reserve_unit ()\n 
		release_unit ()\n
		reserve_unit ()\n 
		release_unit ()\n
		test_unit_ready ()\n
		test_unit_ready ()\n
		test_unit_ready ()\n
		read_element_status(1)\n
		read_element_status(0)\n
		read_element_dvcid()\n
		report_luns()\n
		test_unit_ready ()\n
		test_unit_ready ()\n
		prevent_media_removal (false)\n
		inquiry(0, FALSE, FALSE)\n
		move_medium ($s1a, $s1b)\n
		test_unit_ready ()\n
		test_unit_ready ()\n
		move_medium ($s1b, $s1a)\n
		test_unit_ready ()\n
		test_unit_ready ()\n
		move_medium ($s2a, $s2b)\n
		test_unit_ready ()\n
		test_unit_ready ()\n
		move_medium ($s2b, $s2a)\n
		test_unit_ready ()\n
		test_unit_ready ()\n
		move_medium ($s1a, $s1b)\n
		test_unit_ready ()\n
		test_unit_ready ()\n
		move_medium ($s1b, $s1a)\n
		test_unit_ready ()\n
		test_unit_ready ()\n
		move_medium ($s2a, $s2b)\n
		test_unit_ready ()\n
		test_unit_ready ()\n
		move_medium ($s2b, $s2a)\n	
		test_unit_ready ()\n
		test_unit_ready ()\n
		prevent_media_removal (false)\n
		release_unit()" > $tmptrm

		for i in `seq 1 $loop`; do
		$trifline -o $dev -f $tmptrm
		if [ $? -ne 0 ]; then
		printf "Error in loop #$i ..\n"
		loop=$i		# return with the appropriate failing loop number
		break
		fi
		done
		printf "\n\nPress << ENTER >> to redraw menu.\n\n"
		rm $tmptrm
}

function tr_move_only {
		printf "\nMove cartridges with triffid\n\n"
		tmptrm=`mktemp`
		printf "Enter S1, slot A: "
		read s1a
		printf "Enter S1, slot B: "
		read s1b
		printf "Enter S2, slot A: "
		read s2a
		printf "Enter S2, slot B: "
		read s2b
		printf "Enter device to use: "
		read dev
		printf "Enter number of loops: "
		read loop
		
		if [ -z $dev ] || [ -z $s1a ] || [ -z $s1b ] || [ -z $s2a ] || [ -z $s2b ] || [ -z $loop ]; then
		printf "You must specify all the parameters!\n"
		sleep 3
		break
		fi
		
		
		printf "
		echo (workaround)\n
		stop_on_error(true)\n
		prevent_media_removal (false)\n
		release_unit()\n
		wait(1)\n
		test_unit_ready ()\n
		test_unit_ready ()\n
		move_medium ($s1a, $s1b)\n
		test_unit_ready ()\n
		test_unit_ready ()\n
		move_medium ($s1b, $s1a)\n
		test_unit_ready ()\n
		test_unit_ready ()\n
		move_medium ($s2a, $s2b)\n
		test_unit_ready ()\n
		test_unit_ready ()\n
		move_medium ($s2b, $s2a)\n
		test_unit_ready ()\n
		test_unit_ready ()\n
		move_medium ($s1a, $s1b)\n
		test_unit_ready ()\n
		test_unit_ready ()\n
		move_medium ($s1b, $s1a)\n
		test_unit_ready ()\n
		test_unit_ready ()\n
		move_medium ($s2a, $s2b)\n
		test_unit_ready ()\n
		test_unit_ready ()\n
		move_medium ($s2b, $s2a)\n	
		test_unit_ready ()\n
		test_unit_ready ()\n
		prevent_media_removal (false)\n
		release_unit()" > $tmptrm

		for i in `seq 1 $loop`; do
		printf "\n$i of $loop\n"
		$trifline -o $dev -f $tmptrm
		if [ $? -ne 0 ]; then
		printf "Error in loop #$i ..\n"
		loop=$i		# return with the appropriate failing loop number
		break
		fi
		done
		printf "\n\nPress << ENTER >> to redraw menu.\n\n"
		rm $tmptrm
}

function tr_esl {


		printf "\nNon-FO restricted CMD sequences (ESL)\n\n"
		tmptrm=`mktemp`
		
		printf "Enter device to use: "
		read dev
		printf "Enter number of loops: "
		read loop
		
		if [ -z $dev ] || [ -z $loop ]; then
		printf "You must specify all the parameters!\n"
		sleep 3
		break
		fi
		
		
		printf "
		echo (workaround)\n
		
		stop_on_error(true)\n
		
		prevent_media_removal (false)\n
		test_unit_ready()\n
		test_unit_ready()\n
		release_unit ()\n
		test_unit_ready()\n
		test_unit_ready()\n
		wait(1)
		test_unit_ready()\n
		test_unit_ready()\n
		reserve_unit ()\n 
		test_unit_ready()\n
		test_unit_ready()\n
		wait(1)
		prevent_media_removal (true)\n
		wait(1)
		test_unit_ready()\n
		test_unit_ready()\n
		read_element_status(1)\n
		test_unit_ready()\n
		test_unit_ready()\n
		read_element_status(0)\n
		test_unit_ready()\n
		test_unit_ready()\n
		read_element_dvcid()\n
		test_unit_ready()\n
		test_unit_ready()\n
		report_luns()\n
		test_unit_ready()\n
		test_unit_ready()\n
		inquiry()\n
		test_unit_ready()\n
		test_unit_ready ()\n
		prevent_media_removal (false)\n
		wait(1)
		test_unit_ready()\n
		test_unit_ready()\n
		release_unit ()\n
		wait(1)
		test_unit_ready()\n
		test_unit_ready()\n
		
		
		

		
		prevent_media_removal (false)\n
		release_unit()" > $tmptrm

		for i in `seq 1 $loop`; do
		$trifline -o $dev -f $tmptrm
		if [ $? -ne 0 ]; then
		printf "Error in loop #$i ..\n"
		loop=$i		# return with the appropriate failing loop number
		rm $tmptrm
		break
		fi
		done
		printf "\n\nPress << ENTER >> to redraw menu.\n\n"
		rm $tmptrm

	
}

function progress {
	
  echo -n "Progress: [ "
  while true
  do
    echo -n "#"
    sleep 2
  done
}

function ddmt_single_cmds {
	here=`pwd`
	tmp=DataSet0123456789ABCDEF
	printf "\ndd + mt: single command execution\n\nEnter device file name: "
	read dev
	printf "Enter block size to use (dd): "
	read bs
	printf "Dataset size (MB): "
	read ds
	printf "Number of loops to execute the commands: "
	read loop
	
	if [ -z $dev ] || [ -z $bs ] || [ -z $ds ] || [ -z $loop ]; then
	printf "You must specify all the parameters!\n"
	sleep 3
	break
	fi
	
	
	progress &
	MYSELF=$!
	
	if [ ! -f rand ]; then
	echo -n " [ CC "
	gcc -std=c99 rand.c -o rand			# CHECK WHETHER rand binary exists and try to compile if not..
	echo -n "] "
	fi
	
	"./rand" $ds > $here/$tmp
	kill $MYSELF 2>/dev/null
	wait $MYSELF 2>/dev/null
	echo -n " ] Done."
	echo
	
	
	for i in `seq 1 $loop`; do
	printf "This is loop $i!\n"
	printf "Rewinding.. \n"
	mt -f $dev rewind
	printf "Dumping dataset to drive.. \n"
	dd if=$here/$tmp of=$dev bs=$bs
	if [ $? -ne 0 ]; then
	printf "Oooooops!\n"
	break
	fi
	printf "Reading back all the data ..\n"
	mt -f $dev rewind
	if [ $? -ne 0 ]; then
	printf "Oooooops!\n"
	break
	fi
	dd if=$dev of=$here/back bs=$bs
	if [ $? -ne 0 ]; then
	printf "Oooooops!\n"
	break
	fi
	printf "Comparing data.. \n"
	diff -q $here/back $here/$tmp
	if [ $? -ne 0 ]; then
	printf "Files are not identical!\n"
	break
	else
	printf "Files found identical.\n"
	fi
	
	done
	
	printf "Cleaning up ..\n\n"
	rm -f $here/back $here/$tmp
	printf "Press << ENTER >> to redraw menu.\n\n"
	}

function ddmt_single_cmds_var_bs {
	here=`pwd`
	tmp=DataSet0123456789ABCDEF
	printf "\ndd + mt: single command execution with variable BSs..\n\nEnter device file name: "
	read dev
	printf "Dataset size (MB): "
	read ds
	printf "Number of loops to execute the commands: "
	read loop
	
	if [ -z $dev ] || [ -z $ds ] || [ -z $loop ]; then
	printf "You must specify all the parameters!\n"
	sleep 3
	break
	fi
	
	
	progress &
	MYSELF=$!
	
	if [ ! -f rand ]; then
	echo -n " [ CC "
	gcc -std=c99 rand.c -o rand			# CHECK WHETHER rand binary exists and try to compile if not..
	echo -n "] "
	fi
	
	"./rand" $ds > $here/$tmp
	kill $MYSELF 2>/dev/null
	wait $MYSELF 2>/dev/null
	echo -n " ] Done."
	echo
	
	for j in `seq 1 $loop`; do
	for i in 1024 4096 16384 32768 65536 131072 4097 65535 131080; do
	printf "Loop $j with $i blocksize\n"
	printf "Rewinding. \n"
	mt -f $dev rewind
	printf "Dumping dataset to the drive.. \n"
	dd if=$here/$tmp of=$dev bs=$i
	printf "Reading back all the data ..\n"
	mt -f $dev rewind
	dd if=$dev of=$here/back bs=$i
	printf "Comparing data.. \n"
	diff -q $here/back $here/$tmp
	if [ $? -ne 0 ]; then
	printf "Files are not identical!\n"
	break
	else
	printf "Files found identical.\n"
	fi
	done
	done
	
	printf "Cleaning up ..\n\n"
	rm -f $here/back $here/$tmp
	printf "Press << ENTER >> to redraw menu.\n\n"
}

function discover_changer {

printf "\n\n\nDetecting medium changer.. \n\n"
	
for i in `ls -1 /dev/sg*`; do

if [ -z "`mtx -f $i inquiry | grep Medium | grep Changer`" ]; then
printf ""
else 
printf "$i is a medium changer \n"
fi
done

printf "\nPress << ENTER >> to redraw menu.\n\n"
}

function release_unit {
	printf "\nDevice name to free up: "
	read dev
	
	if [ -z $dev ]; then
	printf "You must specify all the parameters!\n"
	sleep 1
	break
	fi
	
	echo "prevent_media_removal(false)" | $trifline -o $dev
	echo "release_unit()" | $trifline -o $dev
	
	printf "\n\n"
	
	
}

function mtx_esl {
	
	printf "\nmtx: single cycle move medium..\n\n"
	
	for i in `ls -1 /dev/sg*`; do
		if [ -z "`mtx -f $i inquiry | grep Medium | grep Changer`" ]; then
		printf ""
		else 
		changer=$i
		printf "$i detected as medium changer\n"
		fi
	done
	

	printf "Available slots to move: `mtx -f $changer status | grep :Full | grep -v Data | awk '{print $3}' | cut -d: -f1 | tr '\n' ' '`\n"
	printf "Total available slots to move: `mtx -f $changer status | awk '{if(NR>3)print}' | wc -l`\n\n"
	
	printf "[] Please enter changer device file: "
	read dev
	printf "Enter move 1 source: "
	read s1a
	printf "Enter move 1 destination: "
	read d1a
	printf "Enter move 2 source: "
	read s2a
	printf "Enter move 2 destination: "
	read d2a
	printf "Loops = "
	read loops
	
	if [ -z $dev ] || [ -z $s1a ] || [ -z $d1a ] || [ -z $s2a ] || [ -z $d2a ] || [ -z $loops ]; then
	printf "You must specify all the parameters!\n"
	sleep 3
	break
	fi
	
	for i in `seq 1 $loops`; do
	
	
	printf "\nLoop $i/$loops ..\n$s1a => $d1a : "
	$mtx -f $dev eepos 0 transfer $s1a $d1a
	if [ $? -ne 0 ]; then
	break
	else
	printf "ok \n"
	fi
	
	printf "$d1a => $s1a : "
	$mtx -f $dev eepos 0 transfer $d1a $s1a 
	if [ $? -ne 0 ]; then
	break
	else
	printf "ok \n"
	fi
	
	printf "$s2a => $d2a : "
	$mtx -f $dev eepos 0 transfer $s2a $d2a
	if [ $? -ne 0 ]; then
	break
	else
	printf "ok \n"
	fi
	
	printf "$d2a => $s2a : "
	$mtx -f $dev eepos 0 transfer $d2a $s2a
	if [ $? -ne 0 ]; then
	break
	else
	printf "ok \n"
	fi
	
	done

	printf "\nPress << ENTER >> to redraw menu.\n\n"	
}

function dump_paths {
	
	for ((;;))
	do
	echo dump > $rp	
	printf "[DEBUG] Printed active path(s)) to STDERR on `date`, next in 30s .. |=|\n"
	sleep 29
	done
	
}

function cho_trifline {
		
	printf "\nCHO 2 TB test..\n\nDevice name: "
	read dev
	printf "Loops (should be 60): "
	read loop
		
	if [ -z $dev ] || [ -z $loop ]; then
	printf "You must specify all the parameters!\n"
	sleep 2
	break
	fi
	
	dump_paths &
	THIS=$!
	
	for i in `seq 1 $loop`; do
	printf "\nLoop $i of $loop.."
	$trifline -o $dev -f basicrw.trm
	if [ $? -ne 0 ]; then
	printf "Oooops! \n"
	printf "Killing bg process with ID $THIS .. \n"
	kill -9 $THIS 2>/dev/null
	wait $THIS 2>/dev/null
	printf "Exit status code $? ..\n"
	break
	fi
	done
	
	printf "Killing bg process .. \n"
	kill -9 $THIS 2>/dev/null
	wait $THIS 2>/dev/null
	
	printf "\nPress << ENTER >> to redraw menu.\n\n"
}

function cho_dd {
		
	here=`pwd`
	tmp=DataSet0123456789ABCDEF
	printf "\nCHO dd: dataset should be 200M, loop 1500\n\n"
	printf "dd + mt: single command execution\n\nEnter device file name: "
	read dev
	printf "Dataset size (MB): "
	read ds
	printf "Number of loops to execute the commands: "
	read loop
	
	if [ -z $dev ] || [ -z $ds ] || [ -z $loop ]; then
	printf "You must specify all the parameters!\n"
	sleep 3
	break
	fi
	
	# dump paths before data generation and keeps data path reporting
	
	dump_paths &
	THIS=$!
	err=0
	
	for j in `seq 1 $loop`; do
				
			if [ $err -eq 1 ]; then
			printf "Forcing to exit due to an error... \n"
			break
			fi
				
			progress &
			MYSELF=$!
	
			if [ ! -f rand ]; then
				echo -n " [ CC "
				gcc -std=c99 rand.c -o rand			# CHECK WHETHER rand binary exists and try to compile if not..
				echo -n "] "
			fi
	
			"./rand" $ds > $here/$tmp
			kill $MYSELF 2>/dev/null
			wait $MYSELF 2>/dev/null
			echo -n " ] Done."
			echo
	
		
		for i in 4096 16384 32768 65536 131072; do
		
			if [ $err -eq 1 ]; then
			printf "Forcing to exit due to an error... \n"
			break
			fi

		
			printf "[[ STATUS COUNT = $j / $loop; BS = $i ]]\n"
			
			printf "Rewinding .. \n"
			mt -f $dev rewind
			if [ $? -ne 0 ]; then
				printf "Oooooops ($?)!\n"
				printf "Killing bg process with ID $THIS .. \n"
				kill -9 $THIS 2>/dev/null
				wait $THIS 2>/dev/null
				err=1
				printf "Exit status code $? ..\n"
				rm -f $here/back $here/$tmp
				break
			fi	
			
			printf "Dump to tape .. \n"
			dd if=$here/$tmp of=$dev bs=$i
		
			if [ $? -ne 0 ]; then
				printf "Oooooops! ($?)\n"
				printf "Killing bg process with ID $THIS .. \n"
				kill -9 $THIS 2>/dev/null
				wait $THIS 2>/dev/null
				err=1
				printf "Exit status code $? ..\n"
				rm -f $here/back $here/$tmp
				break
			fi

			printf "Rewinding .. \n"
			mt -f $dev rewind
			if [ $? -ne 0 ]; then
				printf "Oooooops! ($?)\n"
				printf "Killing bg process with ID $THIS .. \n"
				kill -9 $THIS 2>/dev/null
				wait $THIS 2>/dev/null
				err=1
				printf "Exit status code $? ..\n"
				rm -f $here/back $here/$tmp
				break
			fi
			
			printf "Read from tape .. \n"
			dd if=$dev of=$here/back bs=$i
		
			if [ $? -ne 0 ]; then
				printf "Oooooops! ($?)\n"
				printf "Killing bg process with ID $THIS .. \n"
				kill -9 $THIS 2>/dev/null
				wait $THIS 2>/dev/null
				err=1
				printf "Exit status code $? ..\n"
				rm -f $here/back $here/$tmp
				break
			fi	


			printf "Comparing data.. \n"
			diff -q $here/back $here/$tmp
		
			if [ $? -ne 0 ]; then
				printf "Files aren't identical! ($?)\n"
				printf "Killing bg process with ID $THIS .. \n"
				kill -9 $THIS 2>/dev/null
				wait $THIS 2>/dev/null
				err=1
				printf "Exit status code $? ..\n"
				rm -f $here/back $here/$tmp
				break
			else
				printf "Files are identical.\n\n"
			fi
								
		done
		
		printf "Cleaning up ..\n\n"
		rm -f $here/back $here/$tmp
	
	done
	
	kill -9 $THIS 2>/dev/null
	wait $THIS 2>/dev/null
	
	printf "Press << ENTER >> to redraw menu.\n\n"
	
	}

function exception {
	
	printf "\nDPF/CPF Xception testing ..\n\nPlease enter device to use:"
		
		
	
		if [ -z $dev ]; then
			printf "You must specify all the parameters!\n"
			sleep 3
			break
		fi
		
		tmptrm=`mktemp`
		
		printf "
		echo (workaround)\n
		reserve_unit ()\n 
		release_unit ()\n
		release_unit()" > $tmptrm

	
	
		for i in `seq 1 $loop`; do
		$trifline -o $dev -f $tmptrm
		if [ $? -ne 0 ]; then
		printf "Error in loop #$i ..\n"
		loop=$i		# return with the appropriate failing loop number
		break
		fi
		done
		printf "\n\nPress << ENTER >> to redraw menu.\n\n"
		rm $tmptrm
}

function path_rotate_on { 
	echo "rotate=1" > $rp 2>/dev/null
	if [ $? -ne 0 ]; then
	printf "Path rotation set failed.\n"
	else
	printf "Path rotation is ON.\n"
	fi
	}

function path_rotate_off {
	echo "rotate=0" > $rp 2>/dev/null
	if [ $? -ne 0 ]; then
	printf "Path rotation set failed.\n"
	else
	printf "Path rotation is OFF.\n"
	fi
	}

function show {
	
	printf "\n\n\nPath status: \n\n"
	
	for i in `ls -1 /dev/sg*`; 
		do 
			echo "inquiry()" | $trifline -o $i
		done
	
	printf "\n\n`cat $path`\n\n"
}

function control_c {
  echo -en "\n\n~:-/ Force quit, cleanup ..\n"
  printf "Killing bg process  .. \n"
  kill -9 $THIS  2>/dev/null
  wait $THIS 2>/dev/null
  kill -9 $MYSELF 2>/dev/null
  wait $MYSELF 2>/dev/null
  rm -Rf $tmp $tmptrm 2>/dev/null
  exit $?
}

function re_boot {
	
	printf "\nRebooting the system, confirmation needed..\n\nTo continue type in the phrase 'Yes, do as I say!'\n"
	read ans
	if [ "$ans" == "Yes, do as I say!" ]; then
	reboot && exit 0
	else
	printf "Abort.. \n\n"
	fi
	
}

trap control_c SIGINT


for ((;;))
	do
		draw_menu
	done
