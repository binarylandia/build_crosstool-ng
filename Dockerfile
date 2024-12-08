ARG DOCKER_BASE_IMAGE
FROM $DOCKER_BASE_IMAGE

ARG DOCKER_BASE_IMAGE
ENV DOCKER_BASE_IMAGE="${DOCKER_BASE_IMAGE}"

SHELL ["bash", "-euxo", "pipefail", "-c"]

RUN set -euxo pipefail >/dev/null \
&& if [[ "$DOCKER_BASE_IMAGE" != centos* ]] && [[ "$DOCKER_BASE_IMAGE" != *manylinux2014* ]]; then exit 0; fi \
&& echo -e "[buildlogs-c7.2009.u]\nname=https://buildlogs.centos.org/c7.2009.u.x86_64/\nbaseurl=https://buildlogs.centos.org/c7.2009.u.x86_64/\nenabled=1\ngpgcheck=0\n\n[buildlogs-c7.2009.00]\nname=https://buildlogs.centos.org/c7.2009.00.x86_64/\nbaseurl=https://buildlogs.centos.org/c7.2009.00.x86_64/\nenabled=1\ngpgcheck=0" > /etc/yum.repos.d/buildlogs.repo \
&& echo -e "[llvm-toolset]\nname=https://buildlogs.centos.org/c7-llvm-toolset-13.0.x86_64/\nbaseurl=https://buildlogs.centos.org/c7-llvm-toolset-13.0.x86_64/\nenabled=1\ngpgcheck=0" > /etc/yum.repos.d/llvm-toolset.repo \
&& sed -i "s/enabled=1/enabled=0/g" "/etc/yum/pluginconf.d/fastestmirror.conf" \
&& sed -i "s/enabled=1/enabled=0/g" "/etc/yum/pluginconf.d/ovl.conf" \
&& yum clean all \
&& yum -y install dnf epel-release \
&& dnf install -y \
  bash \
  ca-certificates \
  curl \
  gcc \
  git \
  gzip \
  make \
  pigz \
  sudo \
  tar \
  xz \
  zstd \
&& dnf clean all \
&& rm -rf /var/cache/yum

RUN set -euxo pipefail >/dev/null \
&& if [[ "$DOCKER_BASE_IMAGE" != debian* ]] && [[ "$DOCKER_BASE_IMAGE" != ubuntu* ]]; then exit 0; fi \
&& export DEBIAN_FRONTEND=noninteractive \
&& apt-get update -qq --yes \
&& apt-get install -qq --no-install-recommends --yes \
  autoconf \
  automake \
  bash \
  binutils \
  bison \
  build-essential \
  ca-certificates \
  curl \
  diffutils \
  file \
  flex \
  g++ \
  gawk \
  gcc \
  git \
  gperf \
  gzip \
  help2man \
  libncurses-dev \
  libncurses5-dev \
  libtool \
  libtool-bin \
  make \
  parallel \
  patch \
  perl \
  pigz \
  python-dev \
  python3 \
  sudo \
  tar \
  texinfo \
  unzip \
  wget \
  xz-utils \
  zstd \
>/dev/null \
&& rm -rf /var/lib/apt/lists/* \
&& apt-get clean autoclean >/dev/null \
&& apt-get autoremove --yes >/dev/null

ENV TMP_CT_NG_BUILD_DIR="/opt/ct-ng"
ENV CT_NG_CONFIG_PATH="/usr/share/crosstool-ng/config"

RUN set -euxo pipefail >/dev/null \
&& mkdir -p "${TMP_CT_NG_BUILD_DIR}" \
&& git clone --recursive "https://github.com/crosstool-ng/crosstool-ng" "${TMP_CT_NG_BUILD_DIR}" \
&& cd "${TMP_CT_NG_BUILD_DIR}" \
&& git checkout "4773bd609c0f788328d6ffc36f6cc9ea8f09a95f" \
&& ./bootstrap \
&& ./configure --prefix="/usr" \
&& make -j$(nproc) \
&& make install \
&& rm -rf "${TMP_CT_NG_BUILD_DIR}" \
&& which ct-ng \
&& ct-ng -v

ARG USER=user
ARG GROUP=user
ARG UID
ARG GID

ENV USER=$USER
ENV GROUP=$GROUP
ENV UID=$UID
ENV GID=$GID
ENV TERM="xterm-256color"
ENV HOME="/home/${USER}"

COPY docker/files /

RUN set -euxo pipefail >/dev/null \
&& /create-user \
&& sed -i /etc/sudoers -re 's/^%sudo.*/%sudo ALL=(ALL:ALL) NOPASSWD: ALL/g' \
&& sed -i /etc/sudoers -re 's/^root.*/root ALL=(ALL:ALL) NOPASSWD: ALL/g' \
&& sed -i /etc/sudoers -re 's/^#includedir.*/## **Removed the include directive** ##"/g' \
&& echo "%sudo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
&& echo "${USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
&& touch ${HOME}/.hushlogin \
&& chown -R ${UID}:${GID} "${HOME}"


USER ${USER}
