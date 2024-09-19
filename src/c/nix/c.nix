{pkgs}: {
  packages = with pkgs; [
    clang-tools
    lldb
    watchexec
    zellij
  ];
}
