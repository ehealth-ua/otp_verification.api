defmodule Core.Factory do
  use ExMachina.Ecto, repo: Core.Repo
  alias Core.SMSLog.Schema, as: SMSLog
  alias Core.Verification.Verification
  alias Core.Verification.VerifiedPhone
  alias Ecto.UUID

  def verification_factory do
    %Verification{
      check_digit: Enum.random(456_800..456_900),
      code: 123_456,
      phone_number: "+38096" <> to_string(Enum.random(1_000_000..9_999_999)),
      status: Enum.random(Verification.status_options()),
      code_expired_at: "2019-08-07T00:00:00.000000Z",
      active: true,
      attempts_count: 1
    }
  end

  def verified_phone_factory do
    %VerifiedPhone{
      phone_number: "+380960000000"
    }
  end

  def sms_logs_factory do
    %SMSLog{
      id: UUID.generate(),
      phone_number: "+380960000000",
      body: "test",
      gateway_id: "gateway_id",
      gateway_status: "Accepted",
      inserted_at: DateTime.utc_now(),
      type: ""
    }
  end
end
