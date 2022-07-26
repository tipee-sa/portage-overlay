# Copyright 2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Google Cloud SDK"
HOMEPAGE="https://cloud.google.com/sdk"
SRC_URI="
	https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/${P}-linux-x86_64.tar.gz
	https://dl.google.com/dl/cloudsdk/channels/rapid/components/google-cloud-sdk-beta-20220719210002.tar.gz
	https://dl.google.com/dl/cloudsdk/channels/rapid/components/google-cloud-sdk-alpha-20220719210002.tar.gz
"
RESTRICT="mirror"

LICENSE="See https://cloud.google.com/terms/"
SLOT="0"
KEYWORDS="-* amd64"

DEPEND=">=dev-lang/python-3.5"
RDEPEND="${DEPEND}"
BDEPEND=""

S="${WORKDIR}/google-cloud-sdk"

src_prepare() {
	default

	# Remove py2 code and _osx code from gsutil
	rm -r ${S}/platform/gsutil_py2 || die "Failed to drop gsutil_py2"
	rm -r ${S}/platform/gsutil/third_party/crcmod_osx || die "Failed to drop crcmod_osx"
	grep -vE '^platform/gsutil_py2|^platform/gsutil/third_party/crcmod_osx' .install/gsutil.manifest > .install/gsutil.manifest.new
	mv .install/gsutil.manifest{.new,}
}

gcloud_install_files() {
	ebegin "$1"
	rsync -a --files-from="${T}/${1}.manifest" ${S}/ ${D}/usr/share/google-cloud-sdk/ || die "Failed to install ${1}"
	eend 0
}

src_install() {
	dodir ${ROOT}/usr/share/google-cloud-sdk

	# gcloud core utils
	cat ${S}/.install/{core,core-nix,gcloud,gcloud-deps,gcloud-deps-linux-x86_64}.manifest > ${T}/gcloud.manifest
	gcloud_install_files gcloud
	dosym ${D}/usr/share/google-cloud-sdk/bin/gcloud /usr/bin/gcloud
	dosym ${D}/usr/share/google-cloud-sdk/bin/docker-credential-gcloud /usr/bin/docker-credential-gcloud

	# alpha and beta wrappers
	mv ${WORKDIR}/lib/surface/{alpha,beta} ${D}/usr/share/google-cloud-sdk/lib/surface

	# gsutil
	cat ${S}/.install/{gsutil,gsutil-nix}.manifest > ${T}/gsutil.manifest
	gcloud_install_files gsutil
	dosym ${D}/usr/share/google-cloud-sdk/bin/gsutil /usr/bin/gsutil
}
