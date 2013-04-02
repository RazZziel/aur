# ==========================================================================
# This ebuild come from flameeyes-overlay repository. Zugaina.org only host a copy.
# For more info go to http://gentoo.zugaina.org/
# ************************ General Portage Overlay ************************
# ==========================================================================
# Copyright 1999-2007 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit elisp versionator eutils

if [[ ${PV} == *_beta ]]; then
	MY_P="${PN/-mode/}-$(replace_version_separator 5 _ $(replace_version_separator 4 _ $(replace_version_separator 3 - $(replace_version_separator 2 - ${PV/_beta/}))))"
else
	MY_P="${PN/-mode/}-$(replace_version_separator 2 -)"
fi

S="${WORKDIR}/nxhtml"

DESCRIPTION="A major mode for GNU Emacs for editing XHTML documents."
HOMEPAGE="http://ourcomments.org/Emacs/nXhtml/doc/nxhtml.html"
if [[ ${PV} ==  *_beta ]]; then
	SRC_URI="http://ourcomments.org/Emacs/DL/elisp/nxhtml/beta/${MY_P}.zip"
else
	SRC_URI="http://ourcomments.org/Emacs/DL/elisp/nxhtml/zip/${MY_P}.zip"
fi

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86"
IUSE=""

EL_DEPEND="|| ( app-emacs/nxml-mode >=virtual/emacs-23 )
	>=app-emacs/php-mode-1.4.0_beta
	app-emacs/fold-dwim
	app-emacs/wikipedia-mode
	app-emacs/snippet
	app-emacs/find-recursive
	app-emacs/cgi+
	app-emacs/csharp-mode
	app-emacs/js2-mode
	!app-emacs/smarty-mode"

DEPEND="${EL_DEPEND}
	app-arch/unzip"
RDEPEND="${EL_DEPEND}
	net-misc/ftpsync"

# Must come after nxml
SITEFILE=60${PN}-gentoo.el

src_unpack() {
	unpack ${A}
	cd "${S}"

	find . -type f \
		-exec chmod -x {} + \
		-exec sed -i -e 's:\r$::' {} +

	# Removing contributed code, most of this stuff is added as
	# dependencies already.
	#
	# moz.el should be removed if we were to package mozrepl
	cd "${S}/related"

	rm csharp-mode.el fold-dwim.el javascript.el php-mode.el \
		php-imenu.el smarty-mode.el tt-mode.el wikipedia-mode.el \
		"${S}"/util/htmlfontify.21.el "${S}"/nxhtml/outline-magic.el \
		|| die "unable to remove contrib code"

	sed -i -e 's:\([^(]\)javascript-mode:\1js2-fl-mode:' \
		"${S}"/util/mumamo.el || die "unable to replace javascript-mode"
}

src_compile() {
	# Regenerate the autoload code.
	emacs --batch --script nxhtmlmaint.el -f nxhtmlmaint-get-all-autoloads \
		|| die "nxhtml-loaddefs.el regen failed"

	emacs --batch --no-site-file -L nxhtml/ -L util/ -L related/ \
		-f batch-byte-compile \
		autostart.el nxhtml-loaddefs.el nxhtml/*.el util/*.el related/*.el
}

src_install() {
	elisp-install ${PN} autostart.el{,c} nxhtml-loaddefs.el{,c}
	for dir in nxhtml util related; do
		elisp-install ${PN}/${dir} ${dir}/*.el{,c} || die "elisp-install in ${dir} failed."
	done
	elisp-site-file-install "${FILESDIR}/${SITEFILE}"

	dodoc readme.txt
	dohtml -r nxhtml/doc/*

	cd "${S}/nxhtml"
	exeinto /usr/libexec/emacs/${PN}
	doexe html-chklnk/link_checker.pl html-wtoc/html-wtoc.pl
	insinto /usr/libexec/emacs/${PN}/PerlLib
	doins -r html-chklnk/PerlLib/* html-wtoc/PerlLib/html_tags.pm
}

pkg_postinst () {
	elisp-site-regen

	if [ $(emacs -batch -q --eval "(princ (fboundp 'nxml-mode))") = nil ]; then
		ewarn "This package needs nxml-mode. You should either install"
		ewarn "app-emacs/nxml-mode, or use \"eselect emacs\" to select"
		ewarn "an Emacs version >= 23."
	fi
}
