FROM rockylinux:8

RUN dnf update -y
RUN dnf group install -y "Development Tools"
RUN dnf install -y openssl-devel bzip2-devel libffi-devel zlib-devel xz-devel libcurl-devel
RUN dnf install -y python3.12 python3.12-devel python3.12-pip
RUN python3.12 -m pip install -U pip setuptools
RUN python3.12 -m pip install poetry

# MongoDB's Bazel build auto-detects the distro from /etc/os-release to download
# the correct pre-built C++ toolchain. Rocky Linux isn't in its detection map,
# but RHEL 8 is — and Rocky 8 is binary-compatible with RHEL 8.
RUN sed -i 's/^NAME=.*/NAME="Red Hat Enterprise Linux"/' /etc/os-release

ADD generate_enterprise_stubs.py .
ADD build.sh .
ENTRYPOINT ["/build.sh"]
