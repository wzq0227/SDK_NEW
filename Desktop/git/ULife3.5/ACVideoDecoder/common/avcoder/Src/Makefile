####################################################################################
#   makefile
####################################################################################


#CROSS = arm-goke-linux-uclibcgnueabi-
#CROSS = arm-hisiv100nptl-linux-
CROSS = arm-hisiv300-linux-

CC	= @echo " $(CROSS)gcc	$@"; $(CROSS)gcc
LD	= @echo " $(CROSS)ld	$@"; $(CROSS)ld
AR	= @echo " $(CROSS)ar	$@"; $(CROSS)ar
RM	= @echo " RM	$@"; rm -f
MV  = mv

INCLUDE =  \
	../Include

LIB   :=libmp4lib.a
LIBDIR:=Lib/
RANDLIB_DIR:=Obj/

SRCS= \
		mp4_builder.c  \
		file_sink.c    \
		mp4_muxer.c    

				
	
OBJS = $(addsuffix .o,$(basename $(SRCS)))

all:$(LIB)
	
$(LIB) :$(OBJS)
	$(AR) -rc $(LIB) $(OBJS)
	$(CC) -I$(INCLUDE) -o mp4 ../mp4.c  $(LIB)
	$(MV) mp4 ../
	$(MV) $(LIB) ../$(LIBDIR)
	$(MV) $(OBJS) ../$(RANDLIB_DIR)
	

%.o : %.c
	$(CC)  $(BASE_CFLAGS) -g -I$(INCLUDE) -c $^ -o $@
		
clean: 
	-rm -rf *.o
	-rm -rf ../$(LIBDIR)$(LIB)
	-rm -rf ../$(RANDLIB_DIR)$(OBJS)

	
	
	
	