defmodule OtpVerification.Web.VerificationsController do
  @moduledoc false
  use OtpVerification.Web, :controller
  use JValid

  alias Core.Verification.Verification
  alias Core.Verification.Verifications
  alias Core.Verification.VerifiedPhone

  action_fallback(OtpVerification.Web.FallbackController)

  use_schema(:initialize_request, "specs/json_schemas/initialize_request_schema.json")
  use_schema(:complete_request, "specs/json_schemas/complete_request_schema.json")

  def show(conn, %{"phone_number" => phone_number}) do
    with %VerifiedPhone{phone_number: phone_number} <- Verifications.get_verified_phone(phone_number) do
      render(conn, "phone.json", verified_phone: phone_number)
    end
  end

  def initialize(conn, params) do
    with :ok <- validate_schema(:initialize_request, params),
         {:ok, %Verification{} = verification} <- Verifications.initialize_verification(params) do
      conn
      |> put_status(:created)
      |> render("show.json", verification: verification)
    end
  end

  def complete(conn, %{"phone_number" => phone_number} = params) do
    params = Map.delete(params, "phone_number")

    with :ok <- validate_schema(:complete_request, params),
         %Verification{active: true} = verification <- Verifications.get_verification_by(phone_number: phone_number),
         code <- Map.fetch!(params, "code"),
         {:ok, %Verification{} = verification, :verified} <- Verifications.verify(verification, code),
         {:ok, %VerifiedPhone{}} <- Verifications.add_verified_phone(verification) do
      conn
      |> put_status(:ok)
      |> put_resp_header("location", verifications_path(conn, :show, verification))
      |> render("show.json", verification: verification)
    end
  end
end
