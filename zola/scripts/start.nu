#!/usr/bin/env nu

export def main [--open] {
  if $open {
    zola serve --open
  } else {
    zola serve
  }
}
