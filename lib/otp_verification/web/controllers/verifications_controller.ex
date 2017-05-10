defmodule OtpVerification.Web.VerificationsController do
  use OtpVerification.Web, :controller

  alias OtpVerification.Verification
  alias OtpVerification.Verification.Verifications

  action_fallback OtpVerification.Web.FallbackController

  def index(conn, _params) do
    verifications = Verification.list_verifications()
    render(conn, "index.json", verifications: verifications)
  end

  def create(conn, %{"verifications" => verifications_params}) do
    with {:ok, %Verifications{} = verifications} <- Verification.create_verifications(verifications_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", verifications_path(conn, :show, verifications))
      |> render("show.json", verifications: verifications)
    end
  end

  def show(conn, %{"id" => id}) do
    verifications = Verification.get_verifications!(id)
    render(conn, "show.json", verifications: verifications)
  end

  def update(conn, %{"id" => id, "verifications" => verifications_params}) do
    verifications = Verification.get_verifications!(id)

    with {:ok, %Verifications{} = verifications} <- Verification.update_verifications(verifications, verifications_params) do
      render(conn, "show.json", verifications: verifications)
    end
  end

  def delete(conn, %{"id" => id}) do
    verifications = Verification.get_verifications!(id)
    with {:ok, %Verifications{}} <- Verification.delete_verifications(verifications) do
      send_resp(conn, :no_content, "")
    end
  end

  def initialize(conn, params) do
    with {:ok, %Verifications{} = verifications} <- Verification.initialize_verifications(params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", verifications_path(conn, :show, verifications))
      |> render("initializes.json", verifications: verifications)
    end
  end
end
