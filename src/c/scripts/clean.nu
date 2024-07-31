#!/usr/bin/env nu

use ./compile.nu get_binary_file_name

export def main [] {
  rm -f out/*
}
