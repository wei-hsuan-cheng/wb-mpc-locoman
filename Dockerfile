# Runtime image for wb-mpc-locoman on arm64 (also support x86_64) without conda.
#
# The PyPI `pin` wheels provide `import pinocchio`, but not the
# `pinocchio.casadi` module used by this project. Build Pinocchio from source
# with CasADi support enabled, while using PyPI/cmeel wheels for the C++
# dependencies that robotpkg does not publish for Linux arm64.
FROM python:3.12-slim-bookworm AS base

ARG PINOCCHIO_VERSION=3.3.1
ARG MAKE_JOBS=2

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PYTHON_SITE_PACKAGES=/usr/local/lib/python3.12/site-packages \
    CMEEL_PREFIX=/usr/local/lib/python3.12/site-packages/cmeel.prefix

ENV PATH="${CMEEL_PREFIX}/bin:${PATH}" \
    CMAKE_PREFIX_PATH="${CMEEL_PREFIX}:${PYTHON_SITE_PACKAGES}/casadi/cmake" \
    PKG_CONFIG_PATH="${CMEEL_PREFIX}/lib/pkgconfig" \
    LIBRARY_PATH="${CMEEL_PREFIX}/lib:${PYTHON_SITE_PACKAGES}/casadi" \
    LD_LIBRARY_PATH="/usr/local/lib:${CMEEL_PREFIX}/lib:${PYTHON_SITE_PACKAGES}/casadi"

RUN apt-get \
       -o Acquire::Check-Date=false \
       -o Acquire::Check-Valid-Until=false \
       update \
    && apt-get install -y --no-install-recommends \
       ca-certificates \
       curl \
       git \
       build-essential \
       cmake \
       ninja-build \
       pkg-config \
       libeigen3-dev \
       liburdfdom-dev \
       x11-apps \
    && rm -rf /var/lib/apt/lists/*

RUN python -m pip install --upgrade pip setuptools wheel \
    && python -m pip install \
       "numpy>=2.2,<2.4" \
       "casadi==3.7.2" \
       "meshcat==0.3.2" \
       "matplotlib==3.11.0" \
       "osqp==1.1.3" \
       "scipy==1.18.0" \
       "pin==${PINOCCHIO_VERSION}" \
    && ln -sfn "${PYTHON_SITE_PACKAGES}/casadi/include/casadi" "${CMEEL_PREFIX}/include/casadi" \
    && ln -sfn "${PYTHON_SITE_PACKAGES}/casadi/libcasadi.so" "${CMEEL_PREFIX}/lib/libcasadi.so"

RUN git clone \
       --branch "v${PINOCCHIO_VERSION}" \
       --depth 1 \
       https://github.com/stack-of-tasks/pinocchio.git \
       /tmp/pinocchio \
    && git -C /tmp/pinocchio submodule update --init --depth 1 cmake \
    && cmake -S /tmp/pinocchio -B /tmp/pinocchio-build -G Ninja \
       -DCMAKE_BUILD_TYPE=Release \
       -DCMAKE_INSTALL_PREFIX=/usr/local \
       -DCMAKE_PREFIX_PATH="${CMEEL_PREFIX};${PYTHON_SITE_PACKAGES}/casadi/cmake" \
       -Dcasadi_DIR="${PYTHON_SITE_PACKAGES}/casadi/cmake" \
       -DBoost_DIR="${CMEEL_PREFIX}/lib/cmake/Boost-1.87.0" \
       -Deigenpy_DIR="${CMEEL_PREFIX}/lib/cmake/eigenpy" \
       -Dhpp-fcl_DIR="${CMEEL_PREFIX}/lib/cmake/hpp-fcl" \
       -Dcoal_DIR="${CMEEL_PREFIX}/lib/cmake/coal" \
       -DPYTHON_EXECUTABLE="$(command -v python)" \
       -DPython_EXECUTABLE="$(command -v python)" \
       -DBUILD_PYTHON_INTERFACE=ON \
       -DBUILD_WITH_CASADI_SUPPORT=ON \
       -DBUILD_WITH_COLLISION_SUPPORT=ON \
       -DBUILD_WITH_URDF_SUPPORT=ON \
       -DBUILD_WITH_AUTODIFF_SUPPORT=OFF \
       -DBUILD_WITH_CODEGEN_SUPPORT=OFF \
       -DBUILD_WITH_OPENMP_SUPPORT=OFF \
       -DBUILD_WITH_EXTRA_SUPPORT=OFF \
       -DBUILD_TESTING=OFF \
       -DBUILD_BENCHMARK=OFF \
       -DBUILD_UTILS=OFF \
       -DINSTALL_DOCUMENTATION=OFF \
       -DGENERATE_PYTHON_STUBS=OFF \
    && cmake --build /tmp/pinocchio-build --target install -j "${MAKE_JOBS}" \
    && python -m pip uninstall -y pin \
    && rm -rf /tmp/pinocchio /tmp/pinocchio-build

RUN python - <<'PY'
import casadi as ca
import pinocchio as pin
import pinocchio.casadi as cpin

x = ca.MX.sym("x")
ca.nlpsol("solver_check", "fatrop", {"x": x, "f": x * x})
print(f"Pinocchio {pin.__version__} with CasADi bindings is available.")
PY

RUN echo 'export XAUTHORITY=$HOME/.xaut/.Xauthority' >> /root/.bashrc

WORKDIR /root