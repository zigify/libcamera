/* SPDX-License-Identifier: LGPL-2.1-or-later */
/*
 * Copyright (C) 2019, Google Inc.
 *
 * V4L2 compatibility layer
 */

#include "v4l2_compat_manager.h"

#include <assert.h>
#include <errno.h>
#include <fcntl.h>
#include <stdarg.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/types.h>

#include <libcamera/base/utils.h>

#define LIBCAMERA_PUBLIC __attribute__((visibility("default")))

using namespace libcamera;

#define extract_va_arg(type, arg, last)	\
{					\
	va_list ap;			\
	va_start(ap, last);		\
	arg = va_arg(ap, type);		\
	va_end(ap);			\
}

namespace {

/*
 * Determine if the flags require a further mode arguments that needs to be
 * parsed from va_args.
 */
bool needs_mode(int flags)
{
	return (flags & O_CREAT) || ((flags & O_TMPFILE) == O_TMPFILE);
}

} /* namespace */

extern "C" {

LIBCAMERA_PUBLIC int open(const char *path, int oflag, ...)
{
	mode_t mode = 0;
	if (needs_mode(oflag))
		extract_va_arg(mode_t, mode, oflag);

	return V4L2CompatManager::instance()->openat(AT_FDCWD, path,
						     oflag, mode);
}

/* _FORTIFY_SOURCE redirects open to __open_2 */
LIBCAMERA_PUBLIC int __open_2(const char *path, int oflag)
{
	assert(!needs_mode(oflag));
	return open(path, oflag);
}

#ifndef open64
LIBCAMERA_PUBLIC int open64(const char *path, int oflag, ...)
{
	mode_t mode = 0;
	if (needs_mode(oflag))
		extract_va_arg(mode_t, mode, oflag);

	return V4L2CompatManager::instance()->openat(AT_FDCWD, path,
						     oflag | O_LARGEFILE, mode);
}

LIBCAMERA_PUBLIC int __open64_2(const char *path, int oflag)
{
	assert(!needs_mode(oflag));
	return open64(path, oflag);
}
#endif

LIBCAMERA_PUBLIC int openat(int dirfd, const char *path, int oflag, ...)
{
	mode_t mode = 0;
	if (needs_mode(oflag))
		extract_va_arg(mode_t, mode, oflag);

	return V4L2CompatManager::instance()->openat(dirfd, path, oflag, mode);
}

LIBCAMERA_PUBLIC int __openat_2(int dirfd, const char *path, int oflag)
{
	assert(!needs_mode(oflag));
	return openat(dirfd, path, oflag);
}

#ifndef openat64
LIBCAMERA_PUBLIC int openat64(int dirfd, const char *path, int oflag, ...)
{
	mode_t mode = 0;
	if (needs_mode(oflag))
		extract_va_arg(mode_t, mode, oflag);

	return V4L2CompatManager::instance()->openat(dirfd, path,
						     oflag | O_LARGEFILE, mode);
}

LIBCAMERA_PUBLIC int __openat64_2(int dirfd, const char *path, int oflag)
{
	assert(!needs_mode(oflag));
	return openat64(dirfd, path, oflag);
}
#endif

LIBCAMERA_PUBLIC int dup(int oldfd)
{
	return V4L2CompatManager::instance()->dup(oldfd);
}

LIBCAMERA_PUBLIC int close(int fd)
{
	return V4L2CompatManager::instance()->close(fd);
}

LIBCAMERA_PUBLIC void *mmap(void *addr, size_t length, int prot, int flags,
			    int fd, off_t offset)
{
	return V4L2CompatManager::instance()->mmap(addr, length, prot, flags,
						   fd, offset);
}

#ifndef mmap64
LIBCAMERA_PUBLIC void *mmap64(void *addr, size_t length, int prot, int flags,
			      int fd, off64_t offset)
{
	return V4L2CompatManager::instance()->mmap(addr, length, prot, flags,
						   fd, offset);
}
#endif

LIBCAMERA_PUBLIC int munmap(void *addr, size_t length)
{
	return V4L2CompatManager::instance()->munmap(addr, length);
}

LIBCAMERA_PUBLIC int ioctl(int fd, unsigned long request, ...)
{
	void *arg;
	extract_va_arg(void *, arg, request);

	return V4L2CompatManager::instance()->ioctl(fd, request, arg);
}

}
