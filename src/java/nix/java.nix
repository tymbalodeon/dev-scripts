{pkgs, ...}: {
  packages = with pkgs; [
    google-java-format
    jdt-language-server
    openjdk
    watchexec
    zellij
  ];
}
