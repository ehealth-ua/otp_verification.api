defmodule OtpVerification.Web.VerificationsController do
  @moduledoc false
  use OtpVerification.Web, :controller

  alias OtpVerification.Verification.Verifications
  alias OtpVerification.Verification.Verification
  alias OtpVerification.Verification.VerifiedPhone

  action_fallback OtpVerification.Web.FallbackController

  def search(conn, params) do
    with changeset = %Ecto.Changeset{valid?: true} <- Verifications.search_changeset(params),
     verifications <- Verifications.search(changeset) do
      render(conn, "index.json", verifications: verifications)
    end
  end

  def show(conn, %{"id" => id}) do
    verification = Verifications.get_verification!(id)
    render(conn, "show.json", verification: verification)
  end

  def initialize(conn, params) do
    with {:ok, %Verification{} = verifications} <- Verifications.initialize_verification(params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", verifications_path(conn, :show, verifications))
      |> render("show.json", verifications: verifications)
    end
  end

  def compele(conn, %{"phone_number" => phone_number, "code" => code}) do
    with %Verification{active: true} = verifications <- Verifications.get_verification_by(phone_number: phone_number),
      {:ok, %Verification{} = verifications, :verified} <- Verifications.verify(verifications, code),
       {:ok, %VerifiedPhone{}} <- Verifications.add_verified_phone(verifications) do
        conn
        |> put_status(:ok)
        |> put_resp_header("location", verifications_path(conn, :show, verifications))
        |> render("show.json", verifications: verifications)
    end
  end
end
