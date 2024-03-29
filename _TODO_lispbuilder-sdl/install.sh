# arg 1:  the new package version

_pkgname=lispbuilder-sdl
_compile_log=n
_lisp=()

if pacman -Qq clisp-new-clx &>/dev/null ||
   pacman -Qq clisp-gtk2 &>/dev/null ||
   pacman -Qq clisp-new-clx &>/dev/null; then
    _lisp=(${_lisp[@]} 'clisp')
fi
if pacman -Qq sbcl &>/dev/null; then
    _lisp=(${_lisp[@]} 'sbcl')
fi
if pacman -Qq cmucl &> /dev/null; then
    _lisp=(${_lisp[@]} 'cmucl')
fi

_compile_sbcl() {
    sbcl --noinform --no-sysinit --no-userinit \
        --eval "(require :asdf)" \
        --eval "(pushnew #p\"/usr/share/common-lisp/systems/\" asdf:*central-registry* :test #'equal)" \
        --eval "(asdf:operate 'asdf:compile-op '${_pkgname})" \
        --eval "(quit)" &> ${_compile_log_file} || return 1
}
_compile_clisp() {
    clisp --silent -norc -x \
        "(load #p\"/usr/share/common-lisp/source/asdf/asdf\")
        (pushnew #p\"/usr/share/common-lisp/systems/\" asdf:*central-registry* :test #'equal)
        (asdf:operate 'asdf:compile-op '${_pkgname})
        (quit)" &> ${_compile_log_file} || return 1
}
_compile_cmucl() {
    cmucl -quiet -nositeinit -noinit -eval \
        "(load #p\"/usr/share/common-lisp/source/asdf/asdf\")
        (pushnew #p\"/usr/share/common-lisp/systems/\" asdf:*central-registry* :test #'equal)
        (asdf:operate 'asdf:compile-op '${_pkgname})
        (quit)" &> ${_compile_log_file} || return 1
}

post_install() {
    for _lispiter in ${_lisp[@]}; do
        echo "---> Compiling lisp files using ${_lispiter} <---"
        if [ $_compile_log = 'y' ]; then
            _compile_log_file=/tmp/${_pkgname}_${_lispiter}.log
        else
            _compile_log_file=/dev/null
        fi
        _compile_${_lispiter}
        echo "---> Done compiling lisp files (using ${_lispiter}) <---"
    done

    cat << EOM

    To load this library, load asdf and then run the following lines
    (or their equivalent for your lisp of choice):

    (push #p"/usr/share/common-lisp/systems/" asdf:*central-registry*)
    (asdf:operate 'asdf:load-op '${_pkgname})
EOM
}

post_upgrade() {
    post_install $1
}

pre_remove() {
    rm -f /usr/share/common-lisp/source/$_pkgname/{*.fas,*.fasl,*.lib,*.x86f}
}

op=$1
shift

$op $*

# End of file
