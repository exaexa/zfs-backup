
DESTDIR=/usr
prefix := ${DESTDIR}/sbin/
progs := zb-cleanup zb-pull zb-snap
targets := $(foreach prog, $(progs), $(prefix)$(prog) )

$(prefix)zb-% : zb-%
	install ${INSTALL_FLAGS} $< $@

install: $(targets)

