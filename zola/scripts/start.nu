#!/usr/bin/env nu

export def main [--open] {
  if $open {
    print "Implement me..."
  } else {
    zellij --layout zellij-layout.kdl
  }
}
