#!/usr/bin/env nu

# View commit history
def --wrapped main [
  ...args: string
] {
  if "--oneline" in $args {
    (
      ^git log
        --pretty=format:'%C(auto)%h%d%C(reset) %C(dim)%ar%C(reset) %C(bold)%s%C(reset) %C(dim blue)(%an)%C(reset)'
        --graph
    )
  } else {
    cog log ...$args
  }
}
