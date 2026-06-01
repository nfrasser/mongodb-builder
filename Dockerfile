FROM rockylinux:8

RUN dnf update -y
RUN dnf group install -y "Development Tools"
RUN dnf install -y openssl-devel bzip2-devel libffi-devel zlib-devel xz-devel libcurl-devel perl-IPC-Cmd
RUN dnf install -y python3.12 python3.12-devel python3.12-pip

# Build OpenSSL 3 from source. Rocky 8 ships OpenSSL 1.1, but target systems
# use OpenSSL 3. Installing to --prefix=/usr overwrites the 1.1 headers and dev
# symlinks so -lssl/-lcrypto link against libssl.so.3 instead of libssl.so.1.1.
RUN curl -L -o openssl-3.0.20.tar.gz https://github.com/openssl/openssl/releases/download/openssl-3.0.20/openssl-3.0.20.tar.gz && \
    tar xzf openssl-3.0.20.tar.gz && \
    cd openssl-3.0.20 && \
    ./config --prefix=/usr --libdir=lib64 shared && \
    make -j$(nproc) && \
    make install_sw && \
    cd / && rm -rf openssl-3.0.20*

RUN python3.12 -m pip install -U pip setuptools
RUN python3.12 -m pip install poetry

# MongoDB's Bazel build auto-detects the distro from /etc/os-release to download
# the correct pre-built C++ toolchain. Rocky Linux isn't in its detection map,
# but RHEL 8 is — and Rocky 8 is binary-compatible with RHEL 8.
RUN sed -i 's/^NAME=.*/NAME="Red Hat Enterprise Linux"/' /etc/os-release

ADD generate_enterprise_stubs.py .
ADD build.sh .
ENTRYPOINT ["/build.sh"]
