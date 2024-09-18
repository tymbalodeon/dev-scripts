{pkgs, ...}: {
  packages = with pkgs; [
    zellij
    zola
  ];
}
