FROM debian:testing-20210408-slim

RUN apt-get update \
 && apt-get install -y curl openssl sqlite3 gcc make \
 && rm -rf /var/lib/apt/lists/*

RUN curl -L https://www.cs.utah.edu/plt/snapshots/current/installers/racket-8.2.0.4-src-builtpkgs.tgz > racket.tgz \
 && tar -xzf racket.tgz \
 && rm -f racket.tgz

RUN cd racket-8.2.0.4/src \
 && ./configure --enable-csonly --prefix=/usr \
 && make -j \
 && make install \
 && cd ../.. \
 && rm -rf racket-8.2.0.4

RUN raco pkg install --auto --scope installation --no-docs --no-cache --batch --jobs 4 \
    base \
    bcrypt \
    binaryio \
    bip32 \
    compiler-lib \
    crypto-lib \
    db-lib \
    ec \
    gregor \
    rosette \
    sha \
    threading-lib \
    uuid \
    "https://github.com/marckn0x/bitcoin.git?commit=4b00289cff50e4c94e3d5c01ea00a55e5bd794be"

RUN racket -e '(require ec bip32 rosette bitcoin)'

RUN apt-get update \
  && apt-get install -y \
     git python gcc pkg-config zlib1g-dev g++ \
     libglib2.0-dev libpixman-1-dev make \
     curl markdown gcc-arm-none-eabi \
  && rm -rf /var/lib/apt/lists/*

COPY ./qemu_stm32 ./qemu_stm32
COPY ./install-qemu_stm32.sh ./
RUN TMPDIR=./ ./install-qemu_stm32.sh && rm -rf /tmp/build

COPY ./stm32_p103_demos ./stm32_p103_demos
RUN cd stm32_p103_demos && make

RUN bash -c '{ \
    r="$(timeout 30 stdbuf -oL grep LED | head -n4)" ; \
    kill "$!" ; \
    if [ "$(wc -l <<<"$r")" == "4" ]; then exit 0; \
      else echo "qemu failed"; exit 1; \
    fi; \
  } < <(exec /usr/local/bin/qemu-system-arm -M stm32-p103 -kernel /stm32_p103_demos/demos/freertos_singlethread/main.bin)'

