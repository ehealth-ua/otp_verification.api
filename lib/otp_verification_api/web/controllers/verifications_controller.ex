defmodule OtpVerification.Web.VerificationsController do
  @moduledoc false
  use OtpVerification.Web, :controller

  alias OtpVerification.Verification
  alias OtpVerification.Verification.Verifications
  alias OtpVerification.Verification.VerifiedPhones

  action_fallback OtpVerification.Web.FallbackController

  def search(conn, params) do
    with changeset = %Ecto.Changeset{valid?: true} <- Verification.search_changeset(params),
     verifications <- Verification.search(changeset) do
      render(conn, "index.json", verifications: verifications)
    end
  end

  def show(conn, %{"id" => id}) do
    verifications = Verification.get_verifications!(id)
    render(conn, "show.json", verifications: verifications)
  end

  def initialize(conn, params) do
    with {:ok, %Verifications{} = verifications} <- Verification.initialize_verifications(params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", verifications_path(conn, :show, verifications))
      |> render("show.json", verifications: verifications)
    end
  end

  def compele(conn, %{"id" => id, "code" => code}) do
    with %Verifications{active: true} = verifications <- Verification.get_verifications(id),
      {:ok, %Verifications{} = verifications, :verified} <- Verification.verify(verifications, code),
       {:ok, %VerifiedPhones{}} <- Verification.add_verified_phone(verifications) do
        conn
        |> put_status(:ok)
        |> put_resp_header("location", verifications_path(conn, :show, verifications))
        |> render("show.json", verifications: verifications)
    end
  end
end
