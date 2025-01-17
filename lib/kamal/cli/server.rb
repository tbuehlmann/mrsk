class Kamal::Cli::Server < Kamal::Cli::Base
  desc "bootstrap", "Set up Docker to run Kamal apps"
  def bootstrap
    missing = []

    on(KAMAL.hosts | KAMAL.accessory_hosts) do |host|
      unless execute(*KAMAL.docker.installed?, raise_on_non_zero_exit: false)
        if execute(*KAMAL.docker.superuser?, raise_on_non_zero_exit: false)
          info "Missing Docker on #{host}. Installing…"
          execute *KAMAL.docker.install
        else
          missing << host
        end
      end
    end

    if missing.any?
      raise "Docker is not installed on #{missing.join(", ")} and can't be automatically installed without having root access and the `curl` command available. Install Docker manually: https://docs.docker.com/engine/install/"
    end
  end
end
