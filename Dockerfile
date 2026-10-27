# syntax=docker/dockerfile:1
# check=experimental=all
ARG DOCKER_BASE_IMAGE
FROM $DOCKER_BASE_IMAGE

ARG DOCKER_BASE_IMAGE
ENV DOCKER_BASE_IMAGE="${DOCKER_BASE_IMAGE}"

SHELL ["bash", "-euxo", "pipefail", "-c"]

RUN set -euxo pipefail >/dev/null \
&& export DEBIAN_FRONTEND=noninteractive \
&& apt-get update -qq \
&& apt-get install --no-install-recommends --yes -qq \
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
  jq \
  libncurses-dev \
  libtool \
  libtool-bin \
  make \
  parallel \
  patch \
  perl \
  pigz \
  pkg-config \
  python3 \
  sudo \
  tar \
  texinfo \
  unzip \
  xz-utils \
  zstd \
>/dev/null \
&& apt-get clean autoclean >/dev/null \
&& apt-get autoremove --yes >/dev/null \
&& rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

COPY --link "docker/files/distrust-compromised-roots" "/"
RUN /distrust-compromised-roots

ENV TMP_CT_NG_BUILD_DIR="/opt/ct-ng"
# crosstool-NG 1.29.0
ARG CT_NG_COMMIT="d7a90ff11aae5e59d6acd8c491f0297c15b7fa37"
ENV CT_NG_COMMIT="${CT_NG_COMMIT}"
ENV CT_NG_CONFIG_PATH="/usr/share/crosstool-ng/config"

# docker/patches holds the changes to crosstool-NG itself; patches/ holds the
# patches that crosstool-NG applies to the packages it builds.
COPY docker/patches /tmp/ct-ng-patches
RUN set -euxo pipefail >/dev/null \
&& mkdir -p "${TMP_CT_NG_BUILD_DIR}" \
&& git clone --recursive "https://github.com/crosstool-ng/crosstool-ng" "${TMP_CT_NG_BUILD_DIR}" \
&& cd "${TMP_CT_NG_BUILD_DIR}" \
&& git checkout "${CT_NG_COMMIT}" \
&& git apply /tmp/ct-ng-patches/*.patch \
&& git -c user.name=build_crosstool-ng -c user.email=build@localhost commit --quiet --all --message="binarylandia patches" \
&& rm -rf /tmp/ct-ng-patches \
&& ./bootstrap \
&& ./configure --prefix="/usr" \
&& make -j$(nproc) \
&& make install \
&& rm -rf "${TMP_CT_NG_BUILD_DIR}" \
&& which ct-ng \
&& ct-ng -v

# The compiler of the programs that run on the build machine, which are the
# tools of every toolchain: GCC 16 on glibc 2.17 (see install-host-gcc).
ENV HOST_GCC_DIR="/opt/host-gcc"
COPY --link "docker/files/fetch" "docker/files/checksums" "docker/files/install-host-gcc" "/"
RUN /install-host-gcc "${HOST_GCC_DIR}"
ENV PATH="${HOST_GCC_DIR}/build-bin:${PATH}"
ENV HOST_GCC_RECORD="${HOST_GCC_DIR}/toolchain.json"

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

COPY --link "docker/files/create-user" "/"

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
