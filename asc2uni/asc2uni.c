/*
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 *
*/

#include <stdio.h>
#include <string.h>

#define VERSION "0.02"

int main(int argc, char **argv) {

	char zero = 0x00;
	
	if (argc < 2) {
		printf("\tSyntax: asc2uni <string>\n\tVersion %s\n",VERSION);
		return 0;
	}
	
	for (unsigned int i = 0; i < strlen(argv[1]); i++) {
		putchar(argv[1][i]);
		putchar(zero);
	}
	return 0;
}
