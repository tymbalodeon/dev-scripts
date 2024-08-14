#!/usr/bin/env nu

use ./compile.nu get_binary_file_name

def main [] {
  rm -f out/*
}
