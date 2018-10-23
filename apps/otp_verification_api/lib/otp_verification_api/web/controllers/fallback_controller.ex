defmodule OtpVerification.Web.FallbackController do
  @moduledoc """
  This controller should be used as `action_fallback` in rest of controllers to remove duplicated error handling.
  """
  use OtpVerification.Web, :controller
  alias Core.Verification.Verification

  def call(conn, {_, _, :not_verified}) do
    conn
    |> put_status(403)
    |> render(EView.Views.Error, :"403", %{message: "Invalid verification code"})
  end

  def call(conn, {_, _, :expired}) do
    conn
    |> put_status(403)
    |> render(EView.Views.Error, :"403", %{message: "Verification code expired"})
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> render(EView.Views.Error, :"404")
  end

  def call(conn, {:error, :too_many_requests}) do
    conn
    |> put_status(429)
    |> put_resp_content_type("application/json")
    |> send_resp(429, Poison.encode!(%{message: "too many requests"}))
  end

  def call(conn, {:error, :service_unavailable}) do
    conn
    |> put_status(503)
    |> render(EView.Views.Error, :"503")
  end

  def call(conn, nil) do
    conn
    |> put_status(:not_found)
    |> render(EView.Views.Error, :"404")
  end

  def call(conn, %Verification{active: false} = _verification) do
    conn
    |> put_status(403)
    |> render(EView.Views.Error, :"403", %{message: "Maximum attempts exceed"})
  end

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> render(EView.Views.ValidationError, :"422", changeset)
  end

  def call(conn, %Ecto.Changeset{valid?: false} = changeset) do
    conn
    |> put_status(:unprocessable_entity)
    |> render(EView.Views.ValidationError, :"422", changeset)
  end

  def call(conn, {:error, json_schema_errors}) when is_list(json_schema_errors) do
    conn
    |> put_status(:unprocessable_entity)
    |> render(EView.Views.ValidationError, :"422", %{schema: json_schema_errors})
  end
end
