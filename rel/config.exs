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

  set(config_providers: [ConfexConfigProvider])
end

release :otp_verification_scheduler do
  set(version: current_version(:otp_verification_scheduler))

  set(
    applications: [
      otp_verification_scheduler: :permanent
    ]
  )

  set(config_providers: [ConfexConfigProvider])
end
