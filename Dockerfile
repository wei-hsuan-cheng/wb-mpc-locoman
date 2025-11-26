# Minimal runtime image for wb-mpc-locoman (Pinocchio via robotpkg, no conda).
FROM python:3.12-slim AS base

ARG PYTHON_VERSION=3.12
ARG ROBOTPKG_PY=312

ENV DEBIAN_FRONTEND=noninteractive

# Base tools and robotpkg repo for Pinocchio.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ca-certificates \
       curl \
       gnupg \
       lsb-release \
       build-essential \
       cmake \
       pkg-config \
       git \
       python3-dev \
       pybind11-dev \
       libeigen3-dev \
       libboost-all-dev \
       liburdfdom-dev \
       libassimp-dev \
       libtinyxml2-dev \
       libyaml-cpp-dev \
       x11-apps \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip before installing Python deps from environment.yaml (via pip).
RUN python -m pip install --no-cache-dir --upgrade pip
RUN python -m pip install --no-cache-dir "numpy<2" casadi meshcat matplotlib osqp

# RUN echo "deb [signed-by=/usr/share/keyrings/robotpkg.gpg] http://robotpkg.openrobots.org/packages/debian/pub $(lsb_release -cs) robotpkg" > /etc/apt/sources.list.d/robotpkg.list \
#     && curl http://robotpkg.openrobots.org/packages/debian/robotpkg.key | tee /usr/share/keyrings/robotpkg.gpg >/dev/null \
#     && apt-get update \
#     && apt-get install -y --no-install-recommends robotpkg-py${ROBOTPKG_PY}-pinocchio \
#     && rm -rf /var/lib/apt/lists/*

# ENV PATH=/opt/openrobots/bin:$PATH
# ENV PKG_CONFIG_PATH=/opt/openrobots/lib/pkgconfig:$PKG_CONFIG_PATH
# ENV LD_LIBRARY_PATH=/opt/openrobots/lib:$LD_LIBRARY_PATH
# ENV PYTHONPATH=/opt/openrobots/lib/python${PYTHON_VERSION}/site-packages:$PYTHONPATH
# ENV PINOCCHIO_MODEL_DIR=/opt/openrobots/share/pinocchio/models

# Container display setting helper
RUN echo "export XAUTHORITY=$HOME/.xaut/.Xauthority" >> ~/.bashrc
WORKDIR /root