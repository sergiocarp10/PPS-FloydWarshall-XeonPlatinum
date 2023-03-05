#!/bin/bash
readonly EXEC_DIR="/bin"
readonly OUT_FILE="output/result.csv"
readonly TIME_FILE="output/script_time.txt"
readonly SUMMARY_FILE="output/summary.csv"
readonly OUTPUT_PROCCESOR="output/proc_output"
readonly OPTIONS="-PC"

#If you want to use the MCDRAM, then leave the next line uncommented.
#MCDRAM="numactl -p 1 "
#If you do not want to use the MCDRAM, comment the previous line and uncomment the following one.
MCDRAM=""

VOLLEY_SIZE=5

#It receives two arguments: BS and T
function runTestVolley(){
	BS=$1
	T=$2
	ARGS="$N $T $OPTIONS"

	for((i=1;i<=$VOLLEY_SIZE;i++)); do
		echo -n $VERSION";"$N";"$BS";"$T";" >> $OUT_FILE
		$MCDRAM.$EXEC_DIR"/BS-"$BS/$VERSION $ARGS >> $OUT_FILE 2>&1
	done
	
	# echo "#" >> $OUT_FILE
}

function setDatetimeFile(){
	if [ $1 == "START" ]
	then
		echo "Script start time:" >> $TIME_FILE
	else
		echo "Script end time:" >> $TIME_FILE
	fi
	date +"%d/%m/%y %H:%M" >> $TIME_FILE
}

function createOrOverwriteOutputFiles(){
	echo "" > $OUT_FILE
	echo "" > $TIME_FILE
}

# runTestVolley $BS $T. It runs $1 times each combination
function runNivel(){

	#GRAPH_SIZES="4096 8192 16384"
	GRAPH_SIZES="4096 8192 16384"
	BLOCK_SIZES="32 64 128"
	THREAD_QUANTITIES="56 112"
	VOLLEY_SIZE=$1
	
	echo "Corriendo pruebas para "$VERSION 
	
	for GRAPH_SIZE in $GRAPH_SIZES; do
		N=$GRAPH_SIZE
		echo "\t N: "$N
		
		for BLOCK_SIZE in $BLOCK_SIZES; do
			for THREAD_QTY in $THREAD_QUANTITIES; do
				runTestVolley $BLOCK_SIZE $THREAD_QTY
			done
		done
	done
}

function runQuickComparison(){
	
	VERSIONS="opt_7_8 opt_9-sem opt_9-cond"
	GRAPH_SIZES="16384"
	BLOCK_SIZES="32 64 128"
	THREAD_QUANTITIES="56"
	VOLLEY_SIZE=$1
	
	for GRAPH_SIZE in $GRAPH_SIZES; do
		N=$GRAPH_SIZE
		
		for BLOCK_SIZE in $BLOCK_SIZES; do
			for THREAD_QTY in $THREAD_QUANTITIES; do
				for VERSION_NAME in $VERSIONS; do
					VERSION=$VERSION_NAME
					runTestVolley $BLOCK_SIZE $THREAD_QTY
				done
			done
		done
	done
}

function runAffinityComparison(){
	export KMP_AFFINITY=granularity=core,scatter
	VERSION="opt_7_8"
	runNivel 3
	
	export KMP_AFFINITY=granularity=core,compact
	VERSION="opt_7_8"
	runNivel 3
	
	#export KMP_AFFINITY=granularity=core,balanced
	#VERSION="opt_7_8"
	#runNivel 3
}


#Feel free to modify this function
function run_tests(){
 
	# Output headers
	echo "Version;N;BS;T;Exec time;GFlops" >> $OUT_FILE
	
	## Quick tests
	#runAffinityComparison

	# En caso de usar optimización 8 o superior, asignar afinidad
	export KMP_AFFINITY=granularity=fine,balanced
	
	# Quick Tests
	runQuickComparison 9

	#VERSION="opt_7_8"
	#runNivel 9

	#VERSION="opt_9-sem"
	#runNivel 9
	
	#VERSION="opt_9-cond-v2"
	#runNivel 9
	
	# ELiminar afinidad definida para optimización 7 o menor
	#export KMP_AFFINITY=
	
	#VERSION="opt_7_8"
	#runNivel 6
	
	#VERSION="opt_6"
	#runNivel 6
	
	#VERSION="opt_5"
	#runNivel 6
	
	#VERSION="opt_4"
	#runNivel 3

	#VERSION="opt_3" 
	#runNivel 3
	
	#VERSION="opt_2"
	#runNivel 1

	#VERSION="opt_0_1"
	#runNivel 1
	
	#runComparison 4
	
	# Chequeo de resultados viejos
	#VERSION="opt_5"
	#N=16384
	#VOLLEY_SIZE=5
	#testAllParams

: <<'END'
	
	N=4096
	VOLLEY_SIZE=5
	testAllParams
	
	N=8192
	VOLLEY_SIZE=5
	testAllParams
	
	N=16384
	VOLLEY_SIZE=5
    	testAllParams

#	N=65536
#	VOLLEY_SIZE=3
#	runTestVolley 32 64
#	runTestVolley 64 64
#	runTestVolley 128 64
#	runTestVolley 32 128
#	runTestVolley 64 128
#	runTestVolley 128 128
#	VOLLEY_SIZE=1
#	runTestVolley 256 128
#	runTestVolley 256 64
END
}

createOrOverwriteOutputFiles
setDatetimeFile "START"
run_tests
echo "" >> $OUT_FILE
setDatetimeFile "END"
./$OUTPUT_PROCCESOR < $OUT_FILE > $SUMMARY_FILE 2>&1

