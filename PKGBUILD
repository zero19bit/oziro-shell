# Maintainer: Oziro contributors
pkgname=oziro-shell
pkgver=0.2.0
pkgrel=1
pkgdesc='Independent Wayland desktop shell for Arch Linux'
arch=('x86_64')
url='https://github.com/zero19bit/oziro-shell'
license=('MIT')
depends=('gtk4' 'webkitgtk-6.0' 'gtk4-layer-shell' 'libpulse')
makedepends=('cargo' 'git' 'nodejs' 'npm' 'pkgconf')
optdepends=(
  'pipewire-pulse: PipeWire-compatible audio service'
  'networkmanager: network controls'
  'bluez: Bluetooth controls'
  'upower: battery and power information'
)
source=("git+https://github.com/zero19bit/oziro-shell.git#branch=main")
sha256sums=('SKIP')

build() {
  cd "$srcdir/oziro-shell"

  npm ci
  npm run build
  cargo build --release -p oziro-shell-host -p oziro-core
}

package() {
  cd "$srcdir/oziro-shell"

  install -Dm755 target/release/oziro-shell-host "$pkgdir/usr/bin/oziro-shell-host"
  install -Dm755 target/release/oziro-core "$pkgdir/usr/bin/oziro-core"

  install -d "$pkgdir/usr/share/oziro/shell-ui"
  cp -a frontend/shell-ui/dist/. "$pkgdir/usr/share/oziro/shell-ui/"

  install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
  install -Dm755 packaging/bin/oziro-session-start \
    "$pkgdir/usr/bin/oziro-session-start"
  install -Dm644 packaging/systemd/user/oziro-shell.service \
    "$pkgdir/usr/lib/systemd/user/oziro-shell.service"
  install -Dm644 packaging/autostart/io.oziro.Desktop.Shell.desktop \
    "$pkgdir/usr/share/xdg/autostart/io.oziro.Desktop.Shell.desktop"
}
