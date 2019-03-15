defmodule OtpVerification.Application do
  @moduledoc """
  This is an entry point of otp_verification_api application.
  """

  use Application
  alias OtpVerification.Web.Endpoint

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Define workers and child supervisors to be supervised
    children = [
      # Start the endpoint when the application starts
      supervisor(Endpoint, [])
    ]

    opts = [strategy: :one_for_one, name: OtpVerification.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
