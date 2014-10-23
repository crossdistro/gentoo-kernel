# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-kernel/gentoo-sources/gentoo-sources-3.16.1.ebuild,v 1.1 2014/08/14 12:17:42 mpagano Exp $

EAPI="5"
ETYPE="sources"
K_WANT_GENPATCHES="base extras experimental"
K_GENPATCHES_VER="2"
K_DEBLOB_AVAILABLE="1"
inherit kernel-2 mount-boot
detect_version
detect_arch

KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86"
HOMEPAGE="http://dev.gentoo.org/~mpagano/genpatches"
IUSE="deblob +grub2 experimental"

DESCRIPTION="Full sources including the Gentoo patchset for the ${KV_MAJOR}.${KV_MINOR} kernel tree"
SRC_URI="${KERNEL_URI} ${GENPATCHES_URI} ${ARCH_URI}"

pkg_postinst() {
	kernel-2_pkg_postinst
	einfo "For more info on this patchset, and how to report problems, see:"
	einfo "${HOMEPAGE}"
	if use grub2; then
		grub2-mkconfig > /boot/grub2/grub.cfg
	fi
}

pkg_postrm() {
    kernel-2_pkg_postrm
}

pkg_setup() {
	export REAL_ARCH="$ARCH"
	unset ARCH; unset LDFLAGS #will interfere with Makefile if set
}

src_prepare() {
	:;
	#mkdir obj
	#cp ${FILESDIR}/config obj/.config
	#make O=obj oldconfig
}

src_compile() {
	install -d "${WORKDIR}"/out/{lib,boot}
	install -d "${T}"/{cache,twork}
	install -d "${WORKDIR}"/build "${WORKDIR}"/out/lib/firmware
	genkernel \
		--no-save-config \
		--no-clean \
		--kernel-config="${FILESDIR}"/config \
		--kernname="${PN}" \
		--build-src="${S}" \
		--build-dst="${WORKDIR}"/build \
		--makeopts="${MAKEOPTS}" \
		--firmware-dst="${WORKDIR}"/out/lib/firmware \
		--cachedir="${T}"/cache \
		--tempdir="${T}"/twork \
		--logfile="${WORKDIR}"/genkernel.log \
		--bootdir="${WORKDIR}"/out/boot \
		--module-prefix="${WORKDIR}"/out \
		kernel || die "genkernel failed"
}

src_install() {
	# copy sources into place:
	dodir /usr/src
	cp -a "${S}" "${D}"/usr/src/linux-${P} || die
	cd "${D}"/usr/src/linux-${P}
	# prepare for real-world use and 3rd-party module building:
	make mrproper || die

	cd ${D}
	cp ${FILESDIR}/group-source-files.pl ${T} || die
	chmod +x ${T}/group-source-files.pl
	${T}/group-source-files.pl -D ${T}/keep-src-files -N ${T}/nokeep-src-files \
		-L usr/src/linux-${P}

	cd "${D}"/usr/src/linux-${P}
	cp "${FILESDIR}"/config .config || die
	yes "" | make oldconfig || die
	make prepare || die
	make scripts || die

	cat ${T}/nokeep-src-files | grep -v '%dir' | sed -e 's#^#'"${D}"'#' | xargs rm -f

	# OK, now the source tree is configured to allow 3rd-party modules to be
	# built against it, since we want that to work since we have a binary kernel
	# built.
	cp -a "${WORKDIR}"/out/* "${D}"/ || die "couldn't copy output files into place"
	# module symlink fixup:
	rm -f "${D}"/lib/modules/*/source || die
	rm -f "${D}"/lib/modules/*/build || die
	cd "${D}"/lib/modules
	# module strip:
	find -iname *.ko -exec strip --strip-debug {} \;
	# back to the symlink fixup:
	local moddir="$(ls -d [23]*)"
	ln -s /usr/src/linux-${P} "${D}"/lib/modules/${moddir}/source || die
	ln -s /usr/src/linux-${P} "${D}"/lib/modules/${moddir}/build || die

	# Fixes FL-14
	cp "${WORKDIR}/build/System.map" "${D}/usr/src/linux-${P}/" || die
	cp "${WORKDIR}/build/Module.symvers" "${D}/usr/src/linux-${P}/" || die

}

