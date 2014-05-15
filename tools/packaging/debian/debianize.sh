#! /bin/bash

###############################################################################
#
#                           The Cling Interpreter
#
# tools/packaging/debianize.sh: Script to compile Cling and produce tarballs
# and/or Debian packages for Ubuntu/Debian platforms.
#
# <more documentation here>
#
# Author: Anirudha Bose <ani07nov@gmail.com>
#
# This file is dual-licensed: you can choose to license it under the University
# of Illinois Open Source License or the GNU Lesser General Public License. See
# LICENSE.TXT for details.
#
###############################################################################

# Uncomment the following line to trace the execution of the shell commands
# set -o xtrace

workdir=~/ec/build
srcdir=${workdir}/cling-src
python=$(type -p python2)
CLING_SRC_DIR=${srcdir}/tools/cling
LLVMRevision=$(curl --silent https://raw.githubusercontent.com/ani07nov/cling/master/LastKnownGoodLLVMSVNRevision.txt)
echo "Last known good LLVM revision is ${LLVMRevision}"

if [ -d "${srcdir}" ]; then
  cd "${srcdir}"
  git clean -f -x -d
  git fetch --tags
  git checkout ROOT-patches-r${LLVMRevision}
  git pull origin refs/tags/ROOT-patches-r${LLVMRevision}
else
  git clone http://root.cern.ch/git/llvm.git "${srcdir}"
  cd "${srcdir}"
  git checkout tags/ROOT-patches-r${LLVMRevision}
fi

if [ -d "${srcdir}/tools/clang" ]; then
  cd "${srcdir}/tools/clang"
  git clean -f -x -d
  git fetch --tags
  git checkout ROOT-patches-r${LLVMRevision}
  git pull origin refs/tags/ROOT-patches-r${LLVMRevision}
else
  git clone http://root.cern.ch/git/clang.git  "${srcdir}/tools/clang"
  cd "${srcdir}/tools/clang"
  git checkout ROOT-patches-r${LLVMRevision}
fi

if [ -d "${srcdir}/tools/cling" ]; then
  cd "${srcdir}/tools/cling"
  git clean -f -x -d
  git fetch --tags
  # Checkout master until we have stable v0.2 tag
  git checkout master
  git pull origin master
  #git checkout $(git describe --match v* --abbrev=0 --tags | head -n 1)
  #git pull origin refs/tags/$(git describe --match v* --abbrev=0 --tags | head -n 1)
else
  git clone http://root.cern.ch/git/cling.git  "${srcdir}/tools/cling"
  cd "${srcdir}/tools/cling"
  git checkout $(git describe --match v* --abbrev=0 --tags | head -n 1)
fi

cd ${CLING_SRC_DIR}
VERSION=$(cat ${CLING_SRC_DIR}/VERSION)

# If development release, then add revision to the version
REVISION=$(git log -n 1 --pretty=format:"%H" | cut -c1-10)
echo "${VERSION}" | grep -qE "dev"
if [ "${?}" = 0 ]; then
  VERSION="${VERSION}"-"${REVISION}"
fi

prefix=${workdir}/cling-${VERSION}

echo "Create temporary build directory: ${builddir}"
mkdir -p ${workdir}/builddir
cd ${workdir}/builddir

echo "Configuring Cling for compilation"
${srcdir}/configure --disable-compiler-version-checks --with-python=${python} --enable-targets=host --prefix=${prefix} --enable-optimized=yes --enable-cxx11

echo "Building Cling..."
cores=$(nproc)
echo "Using ${cores} cores."
make -j${cores}
rm -rf ${prefix}
make install -j${cores}

echo "Compressing ${prefix} to produce a bzip2 tarball..."
cd ${workdir}
tar -cjvf cling_${VERSION}.orig.tar.bz2 -C . $(basename ${prefix})

######################################################
# Debianize the tarball: cling_${VERSION}.orig.tar.bz2
# Can refer to relative paths after this
######################################################

cd "${workdir}"/cling-"${VERSION}"

echo "Create directory: debian"
mkdir -p debian

echo "Create file: debian/source/format"
mkdir -p debian/source
echo "3.0 (quilt)" > debian/source/format

echo "Create file: debian/cling.install"
cat >> debian/cling.install << EOF
bin/* /usr/bin
docs/* /usr/share/doc
include/* /usr/include
lib/* /usr/lib
share/* /usr/share
EOF

echo "Create file: debian/compact"
# Optimize binary compression
echo "7" > debian/compact

echo "Create file: debian/compat"
echo "9" > debian/compat

echo "Create file: debian/control"
cat >> debian/control << EOF
Source: cling
Section: devel
Priority: optional
Maintainer: Cling Developer Team <cling-dev@cern.ch>
Uploaders: Anirudha Bose <ani07nov@gmail.com>
Build-Depends: debhelper (>= 9.0.0)
Standards-Version: 3.9.5
Homepage: http://cling.web.cern.ch/
Vcs-Git: http://root.cern.ch/git/cling.git
Vcs-Browser: http://root.cern.ch/gitweb?p=cling.git;a=summary

Package: cling
Priority: optional
Architecture: any
Depends: \${shlibs:Depends}, \${misc:Depends}
Description: interactive C++ interpreter
 Cling is a new and interactive C++11 standard compliant interpreter built
 on the top of Clang and LLVM compiler infrastructure. Its advantages over
 the standard interpreters are that it has command line prompt and uses
 Just In Time (JIT) compiler for compilation. Many of the developers
 (e.g. Mono in their project called CSharpRepl) of such kind of software
 applications name them interactive compilers.
 .
 One of Cling's main goals is to provide contemporary, high-performance
 alternative of the current C++ interpreter in the ROOT project - CINT. Cling
 serves as a core component of the ROOT system for storing and analyzing the
 data of the Large Hadron Collider (LHC) experiments. The
 backward-compatibility with CINT is major priority during the development.
EOF

echo "Create file: debian/copyright"
cat >> debian/copyright << EOF
Format: http://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: cling
Source: http://root.cern.ch/gitweb?p=cling.git;a=summary

Files: *
Copyright: 2007-2014 by the Authors
License: LGPL-2.0+
Comment: Developed by The ROOT Team; CERN and Fermilab

Files: debian/*
Copyright: 2014 Anirudha Bose <ani07nov@gmail.com>
License: LGPL-2.0+

License: LGPL-2.0+
 This package is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2 of the License, or (at your option) any later version.
 .
 This package is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 Lesser General Public License for more details.
 .
 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>.
 .
 On Debian systems, the complete text of the GNU Lesser General
 Public License can be found in "/usr/share/common-licenses/LGPL-2".
Comment: Cling can also be licensed under University of Illinois/NCSA
 Open Source License (UI/NCSAOSL).
 .
 More information here: https://github.com/vgvassilev/cling/blob/master/LICENSE.TXT
EOF

echo "Create file: debian/rules"
cat >> debian/rules << EOF
#!/usr/bin/make -f
# -*- makefile -*-

%:
	dh \$@

override_dh_auto_build:

override_dh_auto_install:
EOF

# The author of the top level changeset is the one who has to sign the Debian package.
echo "Create file: debian/changelog"
cat >> debian/changelog << EOF
cling (${VERSION}-1) unstable; urgency=low

  * [Debian] Update package to version: ${VERSION}
 -- Anirudha Bose <ani07nov@gmail.com>  $(date --rfc-2822)

EOF
echo "Old Changelog:" >> debian/changelog

cd "${CLING_SRC_DIR}"
git log $(git rev-list HEAD) --format="  * %s%n%n -- %an <%ae>  %cD%n%n" >> "${workdir}"/cling-"${VERSION}"/debian/changelog
cd -

# Create Debian package
debuild

echo "Moving all newly created files to cling-${VERSION}-1"
mkdir "${workdir}"/cling-"${VERSION}"-1
mv "${workdir}"/cling_"${VERSION}"*.deb "${workdir}"/cling-"${VERSION}"-1
mv "${workdir}"/cling_"${VERSION}"*.changes "${workdir}"/cling-"${VERSION}"-1
mv "${workdir}"/cling_"${VERSION}"*.build "${workdir}"/cling-"${VERSION}"-1
mv "${workdir}"/cling_"${VERSION}"*.dsc "${workdir}"/cling-"${VERSION}"-1
mv "${workdir}"/cling_"${VERSION}"*.debian.tar.gz "${workdir}"/cling-"${VERSION}"-1

echo "Cleaning up redundant file.."
rm "${workdir}"/cling_"${VERSION}"*.orig.tar.bz2
rm -R "${workdir}"/cling-"${VERSION}"

echo "Now exiting.."