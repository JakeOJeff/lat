# Maintainer: JakeOJeff [ Paulyn Shemy ]
pkgname=lat
pkgver=0.1.0
pkgrel=1
pkgdesc="A language that compiles to Lua/LOVE2D"
arch=("any")
url="https://github.com/JakeOJeff/lat"
license=("MIT")
depends=("ruby" "love")
source=("$pkgname-$pkgver.tar.gz::https://github.com/JakeOJeff/lat/archive/v$pkgver.tar.gz")
sha256sums=("SKIP")

package() {
  cd "lat-$pkgver"
  install -Dm755 install/install.sh "$pkgdir/usr/bin/lat"
  install -Dm644 -t "$pkgdir/usr/share/lat/compiler" compiler/*
}