#!/usr/bin/make -f
#
# Copyright (C) 2009-2014 Kees Cook <kees@debian.org>
# License: GPLv2 or newer
#
# This file is intended to be included in a Debian rules file so that the
# the calculated HARDENING_CFLAGS and HARDENING_LDFLAGS from this makefile
# can by used in the package's CFLAGS (and/or CXXFLAGS) and LDFLAGS to
# harden the security of a package's resulting binaries. For example:
#
#   include /usr/share/hardening-includes/hardening.make
#   CFLAGS += $(HARDENING_CFLAGS)
#   LDFLAGS += $(HARDENING_LDFLAGS)
#
# and if you need it for C++ compilations:
#
#   CXXFLAGS += $(HARDENING_CFLAGS)
#
#
# By default, all hardening options that are valid for a given architecture
# are enabled. The following can be set before or after including this
# makefile:
#   To disable all hardening:        DEB_BUILD_HARDENING:=0
#   To disable PIE:                  DEB_BUILD_HARDENING_PIE:=0
#   To disable stack protector:      DEB_BUILD_HARDENING_STACKPROTECTOR:=0
#   To disable Fortify Source:       DEB_BUILD_HARDENING_FORTIFY:=0
#   To disable format string checks: DEB_BUILD_HARDENING_FORMAT:=0
#   To disable readonly relocations: DEB_BUILD_HARDENING_RELRO:=0
#   To disable BIND_NOW:             DEB_BUILD_HARDENING_BINDNOW:=0
#
# For more details, see https://wiki.debian.org/Hardening
#
# Thanks to Ryan Niebur for help with the Makefile magicks.
#
# -- Kees Cook <kees@debian.org>

DEB_HOST_ARCH ?= $(shell dpkg-architecture -qDEB_HOST_ARCH 2>/dev/null)
DEB_HOST_ARCH_OS ?= $(shell dpkg-architecture -qDEB_HOST_ARCH_OS 2>/dev/null)

DEB_BUILD_HARDENING ?= 1

ifneq (,$(filter $(DEB_HOST_ARCH_OS), linux knetbsd hurd ))
  # PIE enabled only on linux, knetbsd, and hurd (bugs 430455 and 586215)
  ifeq (,$(filter $(DEB_HOST_ARCH), hppa m68k avr32 ))
    # disabled on hppa (bug number needed)
    # disabled on m68k (bug 451192)
    # disabled on avr32 (bug 574716)
    DEB_BUILD_HARDENING_PIE ?= 1
  endif
endif
DEB_BUILD_HARDENING_PIE ?= 0

ifneq (,$(filter $(DEB_HOST_ARCH), ia64 alpha hppa arm))
  # Stack protector disabled on ia64, alpha, hppa.
  #   "warning: -fstack-protector not supported for this target"
  # Stack protector disabled on arm (ok on armel, armhf).
  #   compiler supports it incorrectly (leads to SEGV)
  DEB_BUILD_HARDENING_STACKPROTECTOR ?= 0
endif
DEB_BUILD_HARDENING_STACKPROTECTOR ?= 1

ifneq (,$(filter $(DEB_HOST_ARCH), ia64 hppa avr32 ))
  DEB_BUILD_HARDENING_RELRO ?= 0
endif
DEB_BUILD_HARDENING_RELRO ?= 1

DEB_BUILD_HARDENING_FORTIFY ?= 1
DEB_BUILD_HARDENING_FORMAT ?= 1
DEB_BUILD_HARDENING_BINDNOW ?= 1

_HARDENED_PIE_CFLAGS  := -fPIE
_HARDENED_PIE_LDFLAGS := -fPIE -pie

_HARDENED_STACKPROTECTOR_CFLAGS := -fstack-protector-strong

# Fortify Source requires that -O1 or higher is used, but that should be
# handled outside of this include file.
_HARDENED_FORTIFY_CFLAGS  := -D_FORTIFY_SOURCE=2

_HARDENED_FORMAT_CFLAGS   := -Wformat -Wformat-security -Werror=format-security

_HARDENED_RELRO_LDFLAGS   := -Wl,-z,relro

_HARDENED_BINDNOW_LDFLAGS := -Wl,-z,now

_hardening_enabled = $(if $(filter $(DEB_BUILD_HARDENING), yes 1 on true),\
$(if $(filter $(1), yes 1 on true),$(2),),)

HARDENING_CFLAGS ?= \
$(call _hardening_enabled,$(DEB_BUILD_HARDENING_PIE),$(_HARDENED_PIE_CFLAGS)) \
$(call _hardening_enabled,$(DEB_BUILD_HARDENING_STACKPROTECTOR),$(_HARDENED_STACKPROTECTOR_CFLAGS)) \
$(call _hardening_enabled,$(DEB_BUILD_HARDENING_FORTIFY),$(_HARDENED_FORTIFY_CFLAGS)) \
$(call _hardening_enabled,$(DEB_BUILD_HARDENING_FORMAT),$(_HARDENED_FORMAT_CFLAGS)) \

HARDENING_LDFLAGS ?= \
$(call _hardening_enabled,$(DEB_BUILD_HARDENING_PIE),$(_HARDENED_PIE_LDFLAGS)) \
$(call _hardening_enabled,$(DEB_BUILD_HARDENING_RELRO),$(_HARDENED_RELRO_LDFLAGS)) \
$(call _hardening_enabled,$(DEB_BUILD_HARDENING_BINDNOW),$(_HARDENED_BINDNOW_LDFLAGS)) \

# Utility macros designed to allow package maintainer to force a given
# hardening feature off in certain areas of a build without disabling
# the option for the entire build. For example:
#   CFLAGS += $(HARDENING_CFLAGS)
#   monkey.o: monkey.c
#       $(CC) $(CFLAGS) $(HARDENING_DISABLE_STACKPROTECTOR_CFLAGS) $< -o $@
HARDENING_DISABLE_STACKPROTECTOR_CFLAGS:=-fno-stack-protector
HARDENING_DISABLE_FORTIFY_CFLAGS:=-U_FORTIFY_SOURCE
HARDENING_DISABLE_FORMAT_CFLAGS:=-Wno-format-security
HARDENING_DISABLE_RELRO_LDFLAGS:=-Wl,-z,norelro
HARDENING_DISABLE_BINDNOW_LDFLAGS:=-Wl,-z,lazy
# Note: GCC does not have a way to just turn off pie (there is no "-nopie")
# so if PIE needs to be disabled for a specific target, the CFLAGS and LDFLAGS
# need to be filtered. For example:
#   monkey: monkey.c
#       $(CC) $(filter-out $(HARDENING_DISABLE_PIE_CFLAGS_FILTER),$(CFLAGS)) \
#             $(filter-out $(HARDENING_DISABLE_PIE_LDFLAGS_FILTER),$(LDFLAGS)) \
#             $< -o $@
#
# Note: when building shared libraries, or with some build frameworks (e.g.
# cmake) that pass "-fPIC" to everything, the "-fPIE" option must be filtered
# out to avoid building shared objects that need PIC but end up only with PIE.
# This is usually indicated by errors at link time that look like this:
#  relocation R_X86_64_PC32 against symbol `foo' can not be used when making a shared object; recompile with -fPIC
# In these cases, the CFLAGS can be filtered to exclude "-fPIE" until this
# is fixed in gcc correctly. For example, on one target:
#   monkey.o: monkey.c
#       $(CC) $(filter-out $(HARDENING_DISABLE_PIE_CFLAGS_FILTER),$(CFLAGS)) \
#             $< -c -o $@
# In cases where mixed shared objects and executable objects are being built,
# "-fPIC" needs to actually replace "-fPIE", since gcc won't distinguish
# between them yet. For example:
#   export CFLAGS=$(shell dpkg-buildflags --get CFLAGS)
#   CFLAGS += $(HARDENING_CFLAGS_PIC) \
#             $(filter-out $(HARDENING_DISABLE_PIE_CFLAGS_FILTER),$(HARDENING_CFLAGS))
#
HARDENING_DISABLE_PIE_CFLAGS_FILTER:=$(_HARDENED_PIE_CFLAGS)
HARDENING_DISABLE_PIE_LDFLAGS_FILTER:=$(_HARDENED_PIE_LDFLAGS)
HARDENING_CFLAGS_PIC:=-fPIC
