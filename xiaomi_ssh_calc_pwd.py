#!/usr/bin/python3
# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2016 xiaooloong
# Copyright (C) 2021 ImmortalWrt.org
#
# Original idea from https://www.right.com.cn/forum/thread-189017-1-1.html

import hashlib
import sys

r1d_salt = 'A2E371B0-B34B-48A5-8C40-A7133F3B5D88'.encode('utf8')
# Salt must be reversed for non-R1D devices
others_salt = '-'.join(list(reversed('d44fb0960aa0-a5e6-4a30-250f-6d2df50a'.split('-')))).encode('utf8')

try:
	sn = sys.argv[1]
except IndexError:
	sn = input('SN: ')

if sn:
	# The alculation method of password:
	# Do md5sum for SN and take the first 8 characters
	#
	# If '/' is not included in SN it's R1D
	print(hashlib.md5(sn.encode('utf8') + others_salt if '/' in sn else r1d_salt).hexdigest()[0:8])
else:
	print('Please input SN!')
	exit(1)
