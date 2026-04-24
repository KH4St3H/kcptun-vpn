#!/bin/bash
export GO111MODULE=on
sum="sha1sum"

if ! hash sha1sum 2>/dev/null; then
	if ! hash shasum 2>/dev/null; then
		echo "I can't see 'sha1sum' or 'shasum'"
		echo "Please install one of them!"
		exit
	fi
	sum="shasum"
fi

UPX=false
if hash upx 2>/dev/null; then
	UPX=true
fi

VERSION=`date -u +%Y%m%d`
LDFLAGS="-X main.VERSION=$VERSION -s -w"
GCFLAGS=""

# os/arch pairs to build. darwin/386 is dropped (unsupported since Go 1.15).
TARGETS=(
	linux/amd64 linux/386 linux/arm64
	darwin/amd64 darwin/arm64
	windows/amd64 windows/386
	freebsd/amd64 freebsd/386
)
for target in ${TARGETS[@]}; do
	os=${target%/*}
	arch=${target#*/}
	suffix=""
	if [ "$os" == "windows" ]
	then
		suffix=".exe"
	fi
	env CGO_ENABLED=0 GOOS=$os GOARCH=$arch go build -ldflags "$LDFLAGS" -gcflags "$GCFLAGS" -o client_${os}_${arch}${suffix} github.com/xtaci/kcptun/client
	env CGO_ENABLED=0 GOOS=$os GOARCH=$arch go build -ldflags "$LDFLAGS" -gcflags "$GCFLAGS" -o server_${os}_${arch}${suffix} github.com/xtaci/kcptun/server
	# UPX does not support darwin/arm64 or arm64 mach-o; skip it there.
	if $UPX && [ "$arch" != "arm64" -o "$os" != "darwin" ]; then upx -9 client_${os}_${arch}${suffix} server_${os}_${arch}${suffix} || true;fi
	tar -zcf kcptun-${os}-${arch}-$VERSION.tar.gz client_${os}_${arch}${suffix} server_${os}_${arch}${suffix}
	$sum kcptun-${os}-${arch}-$VERSION.tar.gz
done

# ARM
ARMS=(5 6 7)
for v in ${ARMS[@]}; do
	env CGO_ENABLED=0 GOOS=linux GOARCH=arm GOARM=$v go build -ldflags "$LDFLAGS" -gcflags "$GCFLAGS" -o client_linux_arm$v  github.com/xtaci/kcptun/client
	env CGO_ENABLED=0 GOOS=linux GOARCH=arm GOARM=$v go build -ldflags "$LDFLAGS" -gcflags "$GCFLAGS" -o server_linux_arm$v  github.com/xtaci/kcptun/server
done
if $UPX; then upx -9 client_linux_arm* server_linux_arm*;fi
tar -zcf kcptun-linux-arm-$VERSION.tar.gz client_linux_arm* server_linux_arm*
$sum kcptun-linux-arm-$VERSION.tar.gz

#MIPS32LE
env CGO_ENABLED=0 GOOS=linux GOARCH=mipsle GOMIPS=softfloat go build -ldflags "$LDFLAGS" -gcflags "$GCFLAGS" -o client_linux_mipsle github.com/xtaci/kcptun/client
env CGO_ENABLED=0 GOOS=linux GOARCH=mipsle GOMIPS=softfloat go build -ldflags "$LDFLAGS" -gcflags "$GCFLAGS" -o server_linux_mipsle github.com/xtaci/kcptun/server
env CGO_ENABLED=0 GOOS=linux GOARCH=mips GOMIPS=softfloat go build -ldflags "$LDFLAGS" -gcflags "$GCFLAGS" -o client_linux_mips github.com/xtaci/kcptun/client
env CGO_ENABLED=0 GOOS=linux GOARCH=mips GOMIPS=softfloat go build -ldflags "$LDFLAGS" -gcflags "$GCFLAGS" -o server_linux_mips github.com/xtaci/kcptun/server

if $UPX; then upx -9 client_linux_mips* server_linux_mips*;fi
tar -zcf kcptun-linux-mipsle-$VERSION.tar.gz client_linux_mipsle server_linux_mipsle
tar -zcf kcptun-linux-mips-$VERSION.tar.gz client_linux_mips server_linux_mips
$sum kcptun-linux-mipsle-$VERSION.tar.gz
$sum kcptun-linux-mips-$VERSION.tar.gz
