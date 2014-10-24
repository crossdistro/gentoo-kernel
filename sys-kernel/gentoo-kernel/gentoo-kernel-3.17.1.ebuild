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

DEPEND=">=sys-kernel/genkernel-3.4.51.2-r1"

USER_CONFIG="/etc/portage/savedconfig/sys-kernel/${PN}"
DISTRO_CONFIG="${FILESDIR}/config-${PV}"

ewarn_file() {
	while read line; do
		ewarn $line
	done < ${1}
}

elog_file() {
	while read line; do
		elog $line
	done < ${1}
}

process_diffs() {
	if [[ -s new_options ]]; then
		ewarn "There are some options enabled in .config that were not known neither to the user nor distro config."
		ewarn "This can happen when the user config based on older kernel version has enabled an option that"
		ewarn "was not enabled in the distro config, and now a new option in newer kernel version depends on it."
		ewarn "Values for these new options are taken from upstream default, which might not be what yout want:"
		ewarn_file new_options
		echo
	fi

	if [[ -s is_missing ]]; then
		ewarn "There are some options in user config that are missing from the final .config file."
		ewarn "This can happen when options are removed in a new kernel version, or due to newly introduced dependencies"
		ewarn "on options that are disabled in the .config."
		ewarn "You should review the list for options important to you:"
		ewarn_file is_missing
		echo
	fi

	if [[ -s was_changed ]]; then
		ewarn "There are some options in .config whose values have changed from the values specified in the user config."
		ewarn "This can happen due to dependency changes in the options, or new options being enabled in the new kernel"
		ewarn "and forcing different values on dependent options."
		ewarn "Changes from 'm' to 'y' should be harmless, other changes should be reviewed:"
		ewarn_file was_changed
		echo
	fi

	if [[ -s was_disabled ]]; then
		elog "There are some options enabled in .config that were disabled in the user config. This can happen if the"
		elog "options are enabled due to other new options being enabled, or due to dependency changes."
		elog "This should be harmless, but you can review the list for options you don't want."
		elog_file was_disabled
		echo
	fi

	if [[ -s dist_was_changed ]]; then
		elog "There are some options in .config whose values have changed from the values specified in the distro config."
		elog "This can happen due to options overriden in the user config forcing different values on dependent options."
		elog "The changes should be harmless, but you can review the list:"
		elog_file dist_was_changed
		echo
	fi

	if [[ -s dist_was_diabled ]]; then
		elog "There are some options enabled in .config that were disabled in the distro config. This can happen if the"
		elog "options are enabled due to other new options being enabled, or due to dependency changes."
		elog "This should be harmless, but you can review the list for options you don't want."
		elog_file dist_was_disabled
		echo
	fi

	if [[ -s dist_is_missing ]]; then
		elog "There are $(wc -l < dist_is_missing) options in the distro config that are missing from the final .config file."
		elog "This can happen e.g. when the user config disables an entire class of drivers, and a new driver of this"
		elog "class is introduced in the new kernel version. This should be harmless."
		echo
	fi

	if [[ -s dist_new_options ]]; then
		elog "There are $(wc -l < dist_new_options) options enabled in .config through the distro config, which were not known when the user config"
		elog "has been created. These include new features and drivers that the kernel team enables by default. This means"
		elog "it should be harmless, but may result in e.g. extra disk space taken by drivers for hardware you do not have."
		echo
	fi
}

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
	mkdir "${T}"/cfg || die
	if [[ -f ${USER_CONFIG} ]]; then
		einfo "Using saved user config from ${USER_CONFIG}"
		cd "${T}"/cfg || die
		cp ${FILESDIR}/user-config.py . || die
		chmod +x user-config.py || die
		./user-config.py --combine ${USER_CONFIG} ${DISTRO_CONFIG} .config || die
		cd "${S}" || die
		make O="${T}"/cfg/ olddefconfig || die
		cd "${T}"/cfg || die
		./user-config.py --diff ${USER_CONFIG} ${DISTRO_CONFIG} .config . || die
		process_diffs
	else
		cp ${DISTRO_CONFIG} "${T}"/cfg/.config
	fi
}

src_compile() {
	install -d "${WORKDIR}"/out/{lib,boot}
	install -d "${T}"/{cache,twork}
	install -d "${WORKDIR}"/build "${WORKDIR}"/out/lib/firmware
	genkernel \
		--no-save-config \
		--no-clean \
		--kernel-config="${T}"/cfg/.config \
		--kernname="${PN}" \
		--kerneldir="${S}" \
		--kernel-outputdir="${WORKDIR}"/build \
		--firmware-dst="${WORKDIR}"/out/lib/firmware \
		--makeopts="${MAKEOPTS}" \
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
	cp "${T}"/cfg/.config .config || die
	make olddefconfig || die
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

