OBJ_DIR=.

CFLAGS += -O2 -Wall -m64
LIBCFLAGS += -O2 -Wall -m64
#CFLAGS += -g -Wall -m64
#LIBCFLAGS += -g -Wall -m64 -DDEBUG
APP=udp_mcd_client

all: ${APP}

${APP} : ${APP}.c
	${CC} ${APP}.c -o $@ ${CFLAGS} -L${PWD} -I${PWD} -lpthread -lrt

clean:
	/bin/rm -f ${APP} *.a $(OBJ_DIR)/*.o
