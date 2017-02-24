# Fully automated Gentoo kernel ebuild

## Usage

Use layman to add the `gentoo-kernel` overlay.

    layman -a kernel

Update your `/etc/portage/package.accept_keywords` to enable the testing
package. Replace `amd64` with your own architecture.

    sys-kernel/gentoo-kernel ~amd64

Build and install the kernel. Repeate this step whenever you install new
packages with new kernel module requirements.

    emerge -av gentoo-kernel

## Technical notes

The following steps are automated by the `gentoo-kernel` package. Some
of the automation can be turned off using package use flags.

  * Configuration using `/etc/kconfig/rules` installed with the
    `kernel-tools` package.
  * Magic configuration using metadata of already installed packages.
  * Kernel and initramfs build and installation.
  * Update of the `/usr/src/linux` symlink.
  * GRUB bootloader configuration update.

Note: The kernel package conflicts with the kernel source package of the
same version.

## Contact

[Pavel Šimerda](https://wiki.gentoo.org/wiki/User:Pavlix)
