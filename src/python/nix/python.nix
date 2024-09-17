{pkgs, ...}: {
  packages = with pkgs; [
    rakudo
    nb
  ];
}
