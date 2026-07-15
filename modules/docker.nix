{ ... }:
{
  virtualisation.docker = {
    enable = false;

    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  environment.sessionVariables = {
    DOCKER_HOST = "unix://$XDG_RUNTIME_DIR/docker.sock";
  };
}
