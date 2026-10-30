# lorien-rice: a smaller title bar (28 px instead of 38) and smaller buttons (15 px instead of 24),
# with the icons scaled to the buttons (upstream draws them 16 px at a fixed offset)
prepare() {
  cd $_pkgname
  sed -i -e 's/ceButtonSpacing = 12;/ceButtonSpacing = 6;/' \
         -e 's/ceButtonWidth = 24;/ceButtonWidth = 15;/' \
         -e 's/ceTitlebarHeight = 38;/ceTitlebarHeight = 28;/' \
         -e 's/adjustedBtnRect.setSize(QSize(16, 16));/adjustedBtnRect.setSize(QSize(ceButtonWidth * 2 \/ 3, ceButtonWidth * 2 \/ 3));/' \
         -e 's/adjustedBtnRect.translate(4, 4);/adjustedBtnRect.translate((ceButtonWidth - ceButtonWidth * 2 \/ 3) \/ 2, (ceButtonWidth - ceButtonWidth * 2 \/ 3) \/ 2);/' \
         src/qadwaitadecorations.cpp
  grep -q 'ceTitlebarHeight = 28;' src/qadwaitadecorations.cpp
  grep -q 'ceButtonWidth \* 2 / 3' src/qadwaitadecorations.cpp
}
