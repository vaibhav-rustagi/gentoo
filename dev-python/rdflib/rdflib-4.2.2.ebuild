# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

PYTHON_COMPAT=( python{2_7,3_{5,6}} )
PYTHON_REQ_USE="sqlite?,threads(+)"

# The usual required for tests
DISTUTILS_IN_SOURCE_BUILD=1

inherit distutils-r1

DESCRIPTION="RDF library containing a triple store and parser/serializer"
HOMEPAGE="https://github.com/RDFLib/rdflib https://pypi.org/project/rdflib/"
SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="alpha amd64 arm arm64 ~hppa ia64 ~mips ppc ppc64 sparc x86 ~amd64-linux ~x86-linux"
IUSE="doc berkdb examples mysql redland sqlite test"

RDEPEND="
	dev-python/isodate[${PYTHON_USEDEP}]
	dev-python/html5lib[${PYTHON_USEDEP}]
	dev-python/pyparsing[${PYTHON_USEDEP}]
	berkdb? ( dev-python/bsddb3[${PYTHON_USEDEP}] )
	mysql? ( dev-python/mysql-python[$(python_gen_usedep python2_7)] )
	redland? ( dev-libs/redland-bindings[python,$(python_gen_usedep python2_7)] )"
DEPEND="${RDEPEND}
	dev-python/setuptools[${PYTHON_USEDEP}]
	test? ( dev-python/sparql-wrapper[${PYTHON_USEDEP}]
		>=dev-python/nose-1.3.1-r1[${PYTHON_USEDEP}] )"

python_prepare_all() {
	# Upstream manufactured .pyc files which promptly break distutils' src_test
	find -name "*.py[oc~]" -delete || die

	# Bug 358189; take out tests that attempt to connect to the network
	 sed -e "/'--with-doctest',/d" -e "/'--doctest-extension=.doctest',/d" \
		-e "/'--doctest-tests',/d" -i run_tests.py || die

	sed -e "s: 'sphinx.ext.intersphinx',::" -i docs/conf.py || die

	# doc build requires examples folder at the upper level of docs
	if use doc; then
		cd docs || die
		ln -sf ../examples . || die
		cd ../ || die
	fi

	distutils-r1_python_prepare_all
}

python_compile_all() {
	# https://github.com/RDFLib/rdflib/issues/510
	if use doc; then
		einfo ""; einfo "Several warnings and Errors present in the build"
		einfo "For a complete build, it is required to install"
		einfo "github.com/gjhiggins/n3_pygments_lexer and"
		einfo "github.com/gjhiggins/sparql_pygments_lexer"
		einfo "outside portage via pip or by cloning. These have not been"
		einfo "given a tagged release by the author and are not in portage"
		einfo ""
		emake -C docs html
	fi
}

python_test() {
	# the default; nose with: --where=./ does not work for python3
	if python_is_python3; then
		pushd "${BUILD_DIR}/src/" > /dev/null
		"${PYTHON}" ./run_tests.py || die "Tests failed under ${EPYTHON}"
		popd > /dev/null
	else
		"${PYTHON}" ./run_tests.py || die "Tests failed under ${EPYTHON}"
	fi
}

python_install_all() {
	use doc && local HTML_DOCS=( docs/_build/html/. )
	if use examples ; then
		docinto examples
		dodoc -r examples/.
	fi

	distutils-r1_python_install_all
}
