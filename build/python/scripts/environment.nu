#!/usr/bin/env nu

const base_url = "https://api.github.com/repos/tymbalodeon/dev-scripts/contents"

def "main add" [] {
  print "Add environment from git repo"
}

def "main list" [] {
  http get ([$base_url src] | path join)
  | get name
  | to text
}

def "main remove" [] {
  print "Remove environment"
}

def "main update" [] {
  print "Update (environment)"
}

def main [] {
  help main
}
