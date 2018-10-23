use Mix.Releases.Config,
  default_release: :default,
  default_environment: :default

environment :default do
  set(pre_start_hooks: "bin/hooks/")
  set(dev_mode: false)
  set(include_erts: true)
  set(include_src: false)

  set(
    overlays: [
      {:template, "rel/templates/vm.args.eex", "releases/<%= release_version %>/vm.args"}
    ]
  )
end

release :otp_verification_api do
  set(version: current_version(:otp_verification_api))

  set(
    applications: [
      otp_verification_api: :permanent
    ]
  )

  set(
    config_providers: [
      {Toml.Provider, [path: "/app/config.toml"]}
    ]
  )
end

release :sms_status_updater do
  set(version: current_version(:sms_status_updater))

  set(
    applications: [
      sms_status_updater: :permanent
    ]
  )

  set(
    config_providers: [
      {Toml.Provider, [path: "/app/config.toml"]}
    ]
  )
end

release :deactivator do
  set(version: current_version(:deactivator))

  set(
    applications: [
      deactivator: :permanent
    ]
  )

  set(
    config_providers: [
      {Toml.Provider, [path: "/app/config.toml"]}
    ]
  )
end

release :terminator do
  set(version: current_version(:terminator))

  set(
    applications: [
      terminator: :permanent
    ]
  )

  set(
    config_providers: [
      {Toml.Provider, [path: "/app/config.toml"]}
    ]
  )
end
