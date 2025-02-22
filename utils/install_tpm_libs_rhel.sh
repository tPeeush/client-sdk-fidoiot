export OPENSSL3_INCLUDE=/opt/openssl/include
export CURL_INCLUDE=/opt/curl/include
export OPENSSL3_LIB=/opt/openssl/lib64
export CURL_LIB=/opt/curl/lib

TPM2_TSS_VER="4.0.1"
TPM2_TSS_LINK="https://github.com/tpm2-software/tpm2-tss/releases/download/$TPM2_TSS_VER/tpm2-tss-$TPM2_TSS_VER.tar.gz --no-check-certificate"
TPM2_ABRMD_VER="3.0.0"
TPM2_ABRMD_LINK="https://github.com/tpm2-software/tpm2-abrmd/releases/download/$TPM2_ABRMD_VER/tpm2-abrmd-$TPM2_ABRMD_VER.tar.gz --no-check-certificate"
TPM2_TOOLS_VER="5.5"
TPM2_TOOLS_LINK="https://github.com/tpm2-software/tpm2-tools/releases/download/$TPM2_TOOLS_VER/tpm2-tools-$TPM2_TOOLS_VER.tar.gz --no-check-certificate"
TPM2_OPENSSL_VER="1.1.1"
TPM2_OPENSSL_LINK="https://github.com/tpm2-software/tpm2-openssl/releases/download/$TPM2_OPENSSL_VER/tpm2-openssl-$TPM2_OPENSSL_VER.tar.gz --no-check-certificate"

PARENT_DIR=`pwd`
cd $PARENT_DIR

install_dependencies()
{
    echo "Install the dependencies..."
    yum -y install \
        autoconf-archive \
        libcmocka \
        libcmocka-devel \
        json-c-devel \
        procps \
        iproute \
        gcc-c++ \
        kernel-devel \
        make \
        git \
        pkg-config \
        gcc \
        libtool \
        automake \
        uthash-devel \
        autoconf \
        doxygen \
        m4 \
        pandoc \
        uriparser-devel \
        dbus-devel \
        glib2-devel \
        dbus-x11 \
        libuuid-devel \
        diffutils \
        libusb-devel \
        libtool-ltdl-devel \
        libini_config-devel

     pip3 install pyyaml PyYAML
}

install_tpm2tss()
{
    echo "Build & Install tpm2-tss version : $TPM2_TSS_VER"
    cd $PARENT_DIR
    rm -f tpm2-tss-$TPM2_TSS_VER.tar.gz
    wget $TPM2_TSS_LINK
    tar -xvzf tpm2-tss-$TPM2_TSS_VER.tar.gz
    cd tpm2-tss-$TPM2_TSS_VER

    ./configure --disable-doxygen-doc --with-udevrulesdir=/etc/udev/rules.d/ PKG_CONFIG_PATH=$OPENSSL3_LIB/pkgconfig/:$CURL_LIB/pkgconfig/ \
    CFLAGS="-I$OPENSSL3_INCLUDE -I$CURL_INCLUDE" LDFLAGS="-L$OPENSSL3_LIB -L$CURL_LIB"
    make -j$(nproc)
    make install

    mkdir -p /var/lib/tpm
    userdel tss
    groupadd tss
    useradd -M -d /var/lib/tpm -s /bin/false -g tss tss
    udevadm control --reload-rules
    udevadm trigger
    ldconfig
}

install_tpm2abrmd()
{
    echo "Build & Install tpm2-abrmd version : $TPM2_ABRMD_VER"
    cd $PARENT_DIR
    rm -f tpm2-abrmd-$TPM2_ABRMD_VER.tar.gz
    wget $TPM2_ABRMD_LINK
    tar -xvzf tpm2-abrmd-$TPM2_ABRMD_VER.tar.gz
    cd tpm2-abrmd-$TPM2_ABRMD_VER
    
    PKG_CONFIG_PATH=/usr/local/lib/pkgconfig/:$OPENSSL3_LIB/pkgconfig/:$CURL_LIB/pkgconfig/ \
    ./configure --with-dbuspolicydir=/etc/dbus-1/system.d --with-systemdsystemunitdir=/lib/systemd/system/ --with-systemdpresetdir=/lib/systemd/system-preset/ \
    CFLAGS="-I$OPENSSL3_INCLUDE -I$CURL_INCLUDE" LDFLAGS="-L$OPENSSL3_LIB -L$CURL_LIB"
    make -j$(nproc)
    make install

    mv /usr/local/share/dbus-1/system-services/com.intel.tss2.Tabrmd.service /usr/share/dbus-1/system-services/
    ldconfig
    service tpm2-abrmd stop
    pkill -HUP dbus-daemon
    systemctl daemon-reload
    service tpm2-abrmd status
    service tpm2-abrmd start
    service tpm2-abrmd status
    systemctl enable tpm2-abrmd.service
}

install_tpm2tools()
{
    echo "Build & Install tpm2-tools version : $TPM2_TOOLS_VER"
    cd $PARENT_DIR
    rm -f  tpm2-tools-$TPM2_TOOLS_VER.tar.gz
    wget $TPM2_TOOLS_LINK
    tar -xvzf tpm2-tools-$TPM2_TOOLS_VER.tar.gz
    cd tpm2-tools-$TPM2_TOOLS_VER

    ./configure PKG_CONFIG_PATH=/usr/local/lib/pkgconfig/ \
    CFLAGS="-I$OPENSSL3_INCLUDE -I$CURL_INCLUDE" LDFLAGS="-L$OPENSSL3_LIB -L$CURL_LIB" \
    CRYPTO_CFLAGS="-I$OPENSSL3_INCLUDE" CURL_CFLAGS=" -I$CURL_INCLUDE" CRYPTO_LIBS="-L$OPENSSL3_LIB" CURL_LIBS="-L$CURL_LIB" \
    LIBS="-lssl -lcrypto -lcurl -ldl"
    make -j$(nproc)
    make install
}

install_tpm2openssl()
{
    echo "Build & Install tpm2-openssl..."
    cd $PARENT_DIR
    rm -f tpm2-openssl-$TPM2_OPENSSL_VER.tar.gz
    wget $TPM2_OPENSSL_LINK
    tar -xvzf tpm2-openssl-$TPM2_OPENSSL_VER.tar.gz
    cd tpm2-openssl-$TPM2_OPENSSL_VER

    ./bootstrap
    ./configure --with-modulesdir=$OPENSSL3_LIB/ossl-modules PKG_CONFIG_PATH=/usr/local/lib/pkgconfig/ \
    CFLAGS="-I$OPENSSL3_INCLUDE -I$CURL_INCLUDE" LDFLAGS="-L$OPENSSL3_LIB -L$CURL_LIB" \
    CRYPTO_CFLAGS="-I$OPENSSL3_INCLUDE" CURL_CFLAGS=" -I$CURL_INCLUDE" CRYPTO_LIBS="-L$OPENSSL3_LIB" CURL_LIBS="-L$CURL_LIB"
    make -j$(nproc)
    make install
    libtool --finish $OPENSSL3_LIB/ossl-modules
    ldconfig
}

uninstall_tpm2tss()
{
    echo "Uninstall tpm2-tss...."
    cd $PARENT_DIR
    cd tpm2-tss-$TPM2_TSS_VER
    make uninstall
}

uninstall_tpm2abrmd()
{
    echo "Uninstall tpm2-abrmd"
    cd $PARENT_DIR
    cd tpm2-abrmd-$TPM2_ABRMD_VER
    systemctl disable tpm2-abrmd.service
    make uninstall
}

uninstall_tpm2tools()
{
    echo "Uninstall tpm2-tools...."
    cd $PARENT_DIR
    cd tpm2-tools-$TPM2_TOOLS_VER
    make uninstall
}

uninstall_tpm2openssl()
{
    echo "Uninstall tpm2-openssl...."
    cd $PARENT_DIR
    cd tpm2-openssl-$TPM2_OPENSSL_VER
    make uninstall
}

install()
{
    echo -e "Installing all the tpm2 libraries..\n\n"
    install_dependencies
    install_tpm2tss
    install_tpm2abrmd
    install_tpm2tools
    install_tpm2openssl
}

uninstall()
{
    echo -e "Uninstalling all the tpm2 libraries..\n\n"
    uninstall_tpm2tss
    uninstall_tpm2abrmd
    uninstall_tpm2tools
    uninstall_tpm2openssl
    cd $PARENT_DIR
    rm -rf tpm2*
}

usage()
{
    echo -e "Usage:
        ./$0 <OPTION>\n
        OPTION:
            -i - Install all tpm2 libraries.
            -u - Uninstall all tpm2 libraries.
            -t - Install only tpm2-tss library.
            -d - Uninstall only tpm2-tss library.
            -h - Help."
}


parse_args()
{
    #Modes
    INSTALL_ALL=1
    UNINSTALL_ALL=2
    INSTALL_TPM2_TSS_ONLY=4
    UNINSTALL_TPM2_TSS_ONLY=8

    mode=0

    while getopts "iutdh" opt; do
        case $opt in
            (i) mode=$(($mode | $INSTALL_ALL));;
            (u) mode=$(($mode | $UNINSTALL_ALL));;
            (t) mode=$(($mode | $INSTALL_TPM2_TSS_ONLY));;
            (d) mode=$(($mode | $UNINSTALL_TPM2_TSS_ONLY_SHIFT));;
            (h | *) usage;
                    exit;;
        esac
    done

    if [ $mode -eq $INSTALL_ALL ]; then
        install
    elif [ $mode -eq $UNINSTALL_ALL ]; then
        uninstall
    elif [ $mode -eq $INSTALL_TPM2_TSS_ONLY ]; then
        install_tpm2tss
    elif [ $mode -eq $UNINSTALL_TPM2_TSS_ONLY ]; then
        uninstall_tpm2tss
    else
        echo -e "Invalid argument!\n"
        usage
    fi
}

parse_args "$@"