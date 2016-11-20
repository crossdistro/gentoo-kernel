# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libnl/libnl-3.2.9999.ebuild,v 1.1 2013/10/23 10:58:30 jer Exp $

EAPI=6
PYTHON_COMPAT=( python{3_3,3_4} )

inherit git-r3 distutils-r1

EGIT_REPO_URI="https://github.com/crossdistro/kernel-tools.git"

DESCRIPTION="Tool for reproducible non-interactive kernel configuration"
LICENSE="GPL-2"
SLOT="0"
