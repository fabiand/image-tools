#
# This makefile includes functionality related to building and
# testing the images which can be created usign the kickstart
# files
#
mkfile_dir := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

DISTRO=
RELEASEVER=

noop:
	@echo Please select a specific target
	@echo make rootfs.qcow2
	@echo This expects rootfs.ks to exist

# Direct for virt-sparsify: http://libguestfs.org/guestfs.3.html#backend
export LIBGUESTFS_BACKEND=direct
# Workaround nest problem: https://bugzilla.redhat.com/show_bug.cgi?id=1195278
export LIBGUESTFS_BACKEND_SETTINGS=force_tcg
export TMPDIR=/var/tmp/
%.qcow2: SPARSE=1
%.qcow2: %.ks
	bash $(mkfile_dir)/anaconda_install $(DISTRO) $(RELEASEVER) $< $@ $(DISK_SIZE)
	- [[ -n "$(SPARSE)" ]] && ( virt-sparsify --in-place $@ \
	  || virt-sparsify --check-tmpdir=continue --compress $@ $@.sparse && mv -v $@.sparse $@ \
	  || virt-sparsify --compress $@ $@.sparse && mv -v $@.sparse $@ ; )

%.raw: %.qcow2
	qemu-img convert -p -S 1M -O raw $< $@

%.squashfs.img: %.raw
	bash $(mkfile_dir)/image_to_squashfs $< $@

%.tar.xz: %.qcow2
	guestfish -i -a $< tar-out / $@ compress:xz

