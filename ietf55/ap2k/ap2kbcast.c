/*
 * ap2kbcast.c
 * Send a AP2000 location packet.
 * Reverse-engineered from watching ORiNOCO's configurator.
 * (i.e. I don't know *why* it works =)
 *
 * Bill Fenner <fenner@research.att.com>
 * 11 November 2002
 *
 * $Id$
 */
#include <stdio.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/select.h>
#include <netinet/in.h>

void printuptime(int);

int
main(int argc, char **argv)
{
	/* want to do siocgifconf and send to all up broadcast addrs */
	int s;
	struct sockaddr_in myside;
	struct sockaddr_in dst;
	unsigned char buf[612];
	struct timeval fin, tmo;
	int one = 1;
	int hdrdisp = 0;

	if (argc < 2) {
		fprintf(stderr, "usage: %s broadcast-address\n", argv[0]);
		exit(1);
	}
	if ((s = socket(AF_INET, SOCK_DGRAM, 0)) < 0) {
		perror("socket");
		exit(1);
	}
	myside.sin_family = AF_INET;
	myside.sin_len = sizeof(myside);
	myside.sin_addr.s_addr = INADDR_ANY;
	myside.sin_port = 0;
	if (bind(s, (struct sockaddr *)&myside, myside.sin_len) < 0) {
		perror("bind");
		exit(1);
	}
	if (setsockopt(s, SOL_SOCKET, SO_BROADCAST, &one, sizeof(one)) < 0) {
		perror("SO_BROADCAST");
		exit(1);
	}
	dst.sin_family = AF_INET;
	dst.sin_len = sizeof(dst);
	dst.sin_addr.s_addr = inet_addr(argv[1]);
	dst.sin_port = htons(2719);
	bzero(buf, sizeof(buf));
	buf[0] = 0xab;	/* ma... */
	buf[1] = 0x01;  /* ..gic */
	if (sendto(s, buf, 612, 0, (struct sockaddr *)&dst, dst.sin_len) < 0) {
		perror("sendto");
		exit(1);
	}
	gettimeofday(&fin, NULL);
	fin.tv_sec += 5;	/* XXX */
	while (1) {
		fd_set r;

		gettimeofday(&tmo, NULL);
		tmo.tv_sec = fin.tv_sec - tmo.tv_sec;
		tmo.tv_usec = fin.tv_usec - tmo.tv_usec;
		if (tmo.tv_usec < 0) {
			tmo.tv_sec--;
			tmo.tv_usec += 1000000;
		}
		if (tmo.tv_sec < 0) {
			break;
		}
		FD_ZERO(&r);
		FD_SET(s, &r);
		select(s + 1, &r, NULL, NULL, &tmo);	/*XXX*/
		if (FD_ISSET(s, &r)) {
			struct sockaddr_in from;
			int fromlen = sizeof(from);
			int len;
			int i;

			if ((len = recvfrom(s, buf, sizeof(buf), 0,
				    (struct sockaddr *)&from, &fromlen)) < 0) {
				perror("recvfrom");
				continue;
			}
			if (!hdrdisp) {
				printf("IP address|HTTP password|system name|version|MAC address|last TFTP server|last file TFTPd|uptime\n");
				hdrdisp = 1;
			}
			printf("%s|", inet_ntoa(from.sin_addr));
			printf("%.32s|", &buf[0x4]);
			printf("%.32s|%.32s", &buf[0x30], &buf[0x55]);
			for (i = 0x24; i < 0x2a; i++)
				printf("%c%x", (i == 0x24) ? '|':':', buf[i]);
			for (i = 0x154; i < 0x158; i++)
				printf("%c%d", (i == 0x154) ? '|':'.', buf[i]);
			printf("|%.32s|", &buf[0x158]);
			printuptime(htonl(*(int *)&buf[0x50])/100);
			printf("\n");
			/* XXX */
			/*
			for (i = 0; i < sizeof(buf); i++) {
				printf("%03x %02x %c|", i, buf[i],
					(buf[i] > 32 && buf[i] < 127) ? buf[i] : '.');
				if ((i+1)%8 == 0)
					printf("\n");
			}
			printf("\n");
			*/
		}
	}
}

void printuptime(int s)
{
	static int t[] = { 604800, 86400, 3600, 60, 1 };
	static char c[] = { 'w', 'd', 'h', 'm', 's' };
	int i;

	for (i = 0; s > 0; i++) {
		if (s > t[i]) {
			printf("%d%c", s / t[i], c[i]);
			s -= (s / t[i]) * t[i];
		}
	}
}
