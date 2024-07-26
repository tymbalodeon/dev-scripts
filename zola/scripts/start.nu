export def main [open: bool] {
  if $open {
    zola serve --open
  } else {
    zola serve
  }
}
