use Mix.Releases.Config,
  default_release: :default,
  default_environment: :default

cookie =
  :sha256
  |> :crypto.hash(System.get_env("ERLANG_COOKIE") || "rzn+us8+3v9B4B0r7jzY1sZ6yhBuh+d1tBdSbncqhZED3+wrpefeLQjxJKOosODS")
  |> Base.encode64()

environment :default do
  set(pre_start_hook: "bin/hooks/pre-start.sh")
  set(dev_mode: false)
  set(include_erts: true)
  set(include_src: false)
  set(cookie: cookie)
end

release :otp_verification_api do
  set(version: current_version(:otp_verification_api))

  set(
    applications: [
      otp_verification_api: :permanent
    ]
  )
end
