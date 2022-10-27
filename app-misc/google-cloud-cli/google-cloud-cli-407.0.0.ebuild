# Copyright 2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Google Cloud SDK"
HOMEPAGE="https://cloud.google.com/sdk"
SRC_URI="
	https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/${P}-linux-x86_64.tar.gz
	https://dl.google.com/dl/cloudsdk/channels/rapid/components/google-cloud-sdk-beta-20221021130956.tar.gz
	https://dl.google.com/dl/cloudsdk/channels/rapid/components/google-cloud-sdk-alpha-20221021130956.tar.gz
	gcloud_module_gkeauth? ( https://dl.google.com/dl/cloudsdk/channels/rapid/components/google-cloud-sdk-gke-gcloud-auth-plugin-linux-x86_64-20221014224505.tar.gz )
"
RESTRICT="mirror"

IUSE="gcloud_module_gkeauth"

LICENSE="See https://cloud.google.com/terms/"
SLOT="0"
KEYWORDS="-* amd64"

DEPEND=">=dev-lang/python-3.5"
RDEPEND="${DEPEND}"
BDEPEND=""

PATCHES=(
	"${FILESDIR}"/disable_updater.patch
)

S="${WORKDIR}/google-cloud-sdk"

src_prepare() {
	default

	# Remove useless stuff from core
	sed -E '/^(deb|rpm)\//d' -i .install/core.manifest || die
	sed -E '/^(install.bat|install.sh)/d' -i .install/core.manifest || die
	sed -E '/^path.(bash|fish|zsh).inc/d' -i .install/core.manifest || die

	# Remove py2 code and _osx code from gsutil
	rm -r ${S}/platform/gsutil_py2 || die "Failed to drop gsutil_py2"
	rm -r ${S}/platform/gsutil/third_party/crcmod_osx || die "Failed to drop crcmod_osx"
	sed '/^/d'
	grep -vE '^platform/gsutil_py2|^platform/gsutil/third_party/crcmod_osx' .install/gsutil.manifest > .install/gsutil.manifest.new
	mv .install/gsutil.manifest{.new,}
}

gcloud_install_files() {
	ebegin "$1"
	rsync -a --files-from="${T}/${1}.manifest" ${S}/ ${D}/usr/lib/google-cloud-sdk/ || die "Failed to install ${1}"
	eend 0
}

src_install() {
	dodir ${ROOT}/usr/lib/google-cloud-sdk

	# gcloud core utils
	cat ${S}/.install/{core,core-nix,gcloud,gcloud-deps,gcloud-deps-linux-x86_64}.manifest > ${T}/gcloud.manifest
	gcloud_install_files gcloud
	dosym ${ROOT}/usr/lib/google-cloud-sdk/bin/gcloud /usr/bin/gcloud
	dosym ${ROOT}/usr/lib/google-cloud-sdk/bin/docker-credential-gcloud /usr/bin/docker-credential-gcloud

	# alpha and beta wrappers
	mv "${WORKDIR}"/lib/surface/{alpha,beta} ${D}/usr/lib/google-cloud-sdk/lib/surface || die

	# gsutil
	cat ${S}/.install/{gsutil,gsutil-nix}.manifest > ${T}/gsutil.manifest
	gcloud_install_files gsutil
	dosym ${ROOT}/usr/lib/google-cloud-sdk/bin/gsutil /usr/bin/gsutil

	# gke-gcloud-auth-plugin
	if use gcloud_module_gkeauth; then
		mv "${WORKDIR}/bin/gke-gcloud-auth-plugin" "${D}/usr/lib/google-cloud-sdk/bin" || die
	fi

	# We need to keep the .install dir as it is the anchor for SDK install path detection
	mv ${S}/.install ${D}/usr/lib/google-cloud-sdk/.install || die
}
