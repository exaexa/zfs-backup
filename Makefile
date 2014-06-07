
DESTDIR=/usr

install:
	cp zb-cleanup ${DESTDIR}/bin/zb-cleanup
	cp zb-pull ${DESTDIR}/bin/zb-pull
	cp zb-snap ${DESTDIR}/bin/zb-snap
	cp zb-cron ${DESTDIR}/bin/zb-cron

