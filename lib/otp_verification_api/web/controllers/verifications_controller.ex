defmodule OtpVerification.Web.VerificationsController do
  @moduledoc false
  use OtpVerification.Web, :controller

  alias OtpVerification.Verification.Verifications
  alias OtpVerification.Verification.Verification
  alias OtpVerification.Verification.VerifiedPhone

  action_fallback OtpVerification.Web.FallbackController

  def show(conn, %{"phone_number" => phone_number}) do
    with %VerifiedPhone{phone_number: phone_number} <- Verifications.get_verified_phone(phone_number) do
      render(conn, "phone.json", verified_phone: phone_number)
    end
  end

  def initialize(conn, params) do
    with {:ok, %Verification{} = verifications} <- Verifications.initialize_verification(params) do
      conn
      |> put_status(:created)
      |> render("show.json", verifications: verifications)
    end
  end

  def compele(conn, %{"phone_number" => phone_number, "code" => code}) do
    with %Verification{active: true} = verification <- Verifications.get_verification_by(phone_number: phone_number),
      {:ok, %Verification{} = verification, :verified} <- Verifications.verify(verification, code),
       {:ok, %VerifiedPhone{}} <- Verifications.add_verified_phone(verification) do
        conn
        |> put_status(:ok)
        |> put_resp_header("location", verifications_path(conn, :show, verification))
        |> render("show.json", verifications: verification)
    end
  end
end
