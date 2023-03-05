#Leave uncommented the appropriate line according to the compiler
#CC = gcc
CC = icc

EXE_DIR = bin/BS-$(BS)
SRC_DIR = src
OBJ_DIR = obj
INPUT_DIR = input
FLOYD_FOLDER = floyd_versions
FLOYD_OBJ_DIR = $(OBJ_DIR)/$(FLOYD_FOLDER)
FLOYD_SRC_DIR = $(SRC_DIR)/$(FLOYD_FOLDER)
INPUT_FILES_GEN = $(INPUT_DIR)/input_files_generator

#Flags when GCC is used
#OMP_FLAG = -fopenmp
#AVX2_FLAG = -mavx2
#AVX512_FLAG = -mavx512f
#INTEL_ARC =

#Flags when ICX is used
OMP_FLAG = -qopenmp
AVX2_FLAG = -xCORE-AVX2 
AVX512_FLAG = -xCORE-AVX512 
INTEL_ARC = -DINTEL_ARC=y

#Choose the SIMD registers width
#Intel-MIC-arc= 512, default=256
SIMD_WIDTH = 512
SIMD_WIDTH_FLAG = -DSIMD_WIDTH=$(SIMD_WIDTH)

#Insert the data type size (eg 32 for float, 64 for double)  
TYPE_SIZE = 64
TYPE_SIZE_FLAG = -DTYPE_SIZE=$(TYPE_SIZE)
MEM_ALIGN_FLAG = -DMEM_ALIGN=SIMD_WIDTH/8 #Divided by byte

BS_FLAG = -DBS=$(BS)

#Uncomment the next line if you want to omit the P matrix compute. Leave it commented if you actually want to compute it.
#NO_PATH = -DNO_PATH=y 

# Especificación de Flags para cada nivel

NAIVESEC_CFLAGS =
NAIVEPAR_CFLAGS =
BLOCK_SEC_CFLAGS =
OPT0_1_CFLAGS =
OPT2_CFLAGS = 
OPT3_CFLAGS = $(AVX2_FLAG)
OPT4_CFLAGS = $(AVX512_FLAG)
OPT5_CFLAGS = $(OPT4_CFLAGS)
OPT6_CFLAGS = $(OPT5_CFLAGS)
OPT7_8_CFLAGS = $(OPT6_CFLAGS)
EXT_EXP_CFLAGS = $(OPT7_8_CFLAGS)

OPT9_CFLAGS = $(OPT7_8_CFLAGS)

# Nombres de programa

V_NAIVE_SEC = naive_sec
V_NAIVE_PAR = naive_par
V_BLOCK_SEC = block_sec
V_OPT_0_1 = opt_0_1
V_OPT_2 = opt_2
V_OPT_3 = opt_3
V_OPT_4 = opt_4
V_OPT_5 = opt_5
V_OPT_6 = opt_6
V_OPT_7_8 = opt_7_8
V_EXT_EXP = extra_exp

V_OPT_9_SEM = opt_9-sem
V_OPT_9_COND_1 = opt_9-cond
V_OPT_9_COND_2 = opt_9-cond-v2

# VERS = $(V_NAIVE_SEC) $(V_NAIVE_PAR) $(V_BLOCK_SEC) $(V_OPT_0_1) $(V_OPT_2) $(V_OPT_3) $(V_OPT_4) $(V_OPT_5) $(V_OPT_6) $(V_OPT_7_8) $(V_EXT_EXP)
VERS = $(V_NAIVE_SEC) $(V_NAIVE_PAR) $(V_BLOCK_SEC) $(V_OPT_0_1) $(V_OPT_2) $(V_OPT_3) $(V_OPT_4) $(V_OPT_5) $(V_OPT_6) $(V_OPT_7_8) $(V_OPT_9_SEM) $(V_OPT_9_COND_1) $(V_OPT_9_COND_2)

EXE = $(VERS:%=$(EXE_DIR)/%)
SRC = $(wildcard $(SRC_DIR)/*.c)
OBJ = $(SRC:$(SRC_DIR)/%.c=$(OBJ_DIR)/%.o)

#Needed for the clean
FLOYD_OBJ = $(wildcard $(FLOYD_OBJ_DIR)/*.o)

# CFLAGS += -Iinclude -O3 -Wall -Wextra $(INTEL_ARC) $(OMP_FLAG) $(NO_PATH) $(BS_FLAG) $(TYPE_SIZE_FLAG)
CFLAGS += -Iinclude -O3 -Wall -Wextra $(INTEL_ARC) $(OMP_FLAG) $(MEM_ALIGN_FLAG) $(NO_PATH) $(BS_FLAG) $(SIMD_WIDTH_FLAG) $(TYPE_SIZE_FLAG) -diag-disable=10441
LDFLAGS += $(OMP_FLAG) -diag-disable=10441

# agrego esto para evitar la vectorización
CFLAGS_NO_VEC += -Iinclude -O1 -Wall -Wextra $(INTEL_ARC) $(OMP_FLAG) $(MEM_ALIGN_FLAG) $(NO_PATH) $(BS_FLAG) $(SIMD_WIDTH_FLAG) $(TYPE_SIZE_FLAG) -diag-disable=10441

.PHONY: all clean

all: $(EXE) $(INPUT_FILES_GEN)


INPUT_FILES_OBJS = $(OBJ_DIR)/$(FLOYD_FOLDER)/$(V_NAIVE_PAR).o $(OBJ_DIR)/test_graphs.o $(INPUT_FILES_GEN).o $(OBJ_DIR)/APSP_ADT.o $(OBJ_DIR)/graph_basics.o

$(INPUT_FILES_GEN): $(INPUT_FILES_OBJS)
	$(CC) $(LDFLAGS) $(LDLIBS) $(INPUT_FILES_OBJS) -o $(INPUT_FILES_GEN)

$(INPUT_FILES_GEN).o: $(INPUT_FILES_GEN).c
	$(CC) $(CFLAGS) -c $(INPUT_FILES_GEN).c -o $(INPUT_FILES_GEN).o


$(EXE_DIR)/%: $(OBJ) $(FLOYD_OBJ_DIR)/%.o
	$(CC) $(LDFLAGS) $^ $(LDLIBS) -o $@

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c
	$(CC) $(CFLAGS) -c $< -o $@


#On the following lines, uncomment the ending '.asm' lines if you want to generate the corresponding assembler. Leave them commented for better compiling time performance

$(FLOYD_OBJ_DIR)/$(V_NAIVE_SEC).o: $(FLOYD_SRC_DIR)/$(V_NAIVE_SEC).c
#	$(CC) $(CFLAGS) $(NAIVESEC_CFLAGS) -S $< -o asm/$(V_NAIVE_SEC).asm
	$(CC) $(CFLAGS) $(NAIVESEC_CFLAGS) -c $< -o $@

$(FLOYD_OBJ_DIR)/$(V_NAIVE_PAR).o: $(FLOYD_SRC_DIR)/$(V_NAIVE_PAR).c
#	$(CC) $(CFLAGS) $(NAIVEPAR_CFLAGS) -S $< -o asm/$(V_NAIVE_PAR).asm
	$(CC) $(CFLAGS) $(NAIVEPAR_CFLAGS) -c $< -o $@
	
$(FLOYD_OBJ_DIR)/$(V_BLOCK_SEC).o: $(FLOYD_SRC_DIR)/$(V_BLOCK_SEC).c
#	$(CC) $(CFLAGS) $(BLOCKSEC_CFLAGS) -S $< -o asm/$(V_BLOCK_SEC).asm
	$(CC) $(CFLAGS) $(BLOCKSEC_CFLAGS) -c $< -o $@

# MODIFICADO PARA EVITAR LA VECTORIZACION (-O3 a -O1)
$(FLOYD_OBJ_DIR)/$(V_OPT_0_1).o: $(FLOYD_SRC_DIR)/$(V_OPT_0_1).c
	$(CC) $(CFLAGS_NO_VEC) $(OPT0_1_CFLAGS) -c $< -o $@

$(FLOYD_OBJ_DIR)/$(V_OPT_2).o: $(FLOYD_SRC_DIR)/$(V_OPT_2).c
#	$(CC) $(CFLAGS) $(OPT2_CFLAGS) -S $< -o asm/$(V_OPT_2).asm
	$(CC) $(CFLAGS) $(OPT2_CFLAGS) -c $< -o $@
	
$(FLOYD_OBJ_DIR)/$(V_OPT_3).o: $(FLOYD_SRC_DIR)/$(V_OPT_3).c
#	$(CC) $(CFLAGS) $(OPT3_CFLAGS) -S $< -o asm/$(V_OPT_3).asm
	$(CC) $(CFLAGS) $(OPT3_CFLAGS) -c $< -o $@

$(FLOYD_OBJ_DIR)/$(V_OPT_4).o: $(FLOYD_SRC_DIR)/$(V_OPT_4).c
#	$(CC) $(CFLAGS) $(OPT4_CFLAGS) -S $< -o asm/$(V_OPT_4).asm
	$(CC) $(CFLAGS) $(OPT4_CFLAGS) -c $< -o $@
	
$(FLOYD_OBJ_DIR)/$(V_OPT_5).o: $(FLOYD_SRC_DIR)/$(V_OPT_5).c
	$(CC) $(CFLAGS) $(OPT5_CFLAGS) -c $< -o $@

$(FLOYD_OBJ_DIR)/$(V_OPT_6).o: $(FLOYD_SRC_DIR)/$(V_OPT_6).c
	$(CC) $(CFLAGS) $(OPT6_CFLAGS) -c $< -o $@

$(FLOYD_OBJ_DIR)/$(V_OPT_7_8).o: $(FLOYD_SRC_DIR)/$(V_OPT_7_8).c
	$(CC) $(CFLAGS) $(OPT7_8_CFLAGS) -c $< -o $@

# Nuevas versiones implementadas
$(FLOYD_OBJ_DIR)/$(V_OPT_9_SEM).o: $(FLOYD_SRC_DIR)/$(V_OPT_9_SEM).c
	$(CC) $(CFLAGS) $(OPT9_CFLAGS) -c $< -o $@

$(FLOYD_OBJ_DIR)/$(V_OPT_9_COND_1).o: $(FLOYD_SRC_DIR)/$(V_OPT_9_COND_1).c
	$(CC) $(CFLAGS) $(OPT9_CFLAGS) -c $< -o $@

$(FLOYD_OBJ_DIR)/$(V_OPT_9_COND_2).o: $(FLOYD_SRC_DIR)/$(V_OPT_9_COND_2).c
	$(CC) $(CFLAGS) $(OPT9_CFLAGS) -c $< -o $@

#$(FLOYD_OBJ_DIR)/$(V_INC1_O78).o: $(FLOYD_SRC_DIR)/$(V_INC1_O78).c
#	$(CC) $(CFLAGS) $(OPT7_8_CFLAGS) -c $< -o $@  

#$(FLOYD_OBJ_DIR)/$(V_INC1_O78_V4).o: $(FLOYD_SRC_DIR)/$(V_INC1_O78_V4).c
#	$(CC) $(CFLAGS) $(OPT7_8_CFLAGS) -c $< -o $@

#$(FLOYD_OBJ_DIR)/$(V_EXT_EXP).o: $(FLOYD_SRC_DIR)/$(V_EXT_EXP).c
#	$(CC) $(CFLAGS) $(EXT_EXP_CFLAGS) -c $< -o $@

clean:
	$(RM) $(OBJ) $(FLOYD_OBJ) $(INPUT_FILES_GEN).o
