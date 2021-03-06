defmodule OtpVerification.Web.FallbackController do
  @moduledoc """
  This controller should be used as `action_fallback` in rest of controllers to remove duplicated error handling.
  """
  use OtpVerification.Web, :controller

  alias Core.Verification.Verification
  alias EView.Views.Error
  alias EView.Views.ValidationError

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(Error)
    |> render(:"404")
  end

  def call(conn, {:error, :too_many_requests}) do
    conn
    |> put_status(429)
    |> put_resp_content_type("application/json")
    |> send_resp(429, Jason.encode!(%{message: "too many requests"}))
  end

  def call(conn, {:error, :service_unavailable}) do
    conn
    |> put_status(503)
    |> put_view(Error)
    |> render(:"503")
  end

  def call(conn, nil) do
    conn
    |> put_status(:not_found)
    |> put_view(Error)
    |> render(:"404")
  end

  def call(conn, {:error, {:forbidden, message}}) do
    conn
    |> put_status(403)
    |> put_view(Error)
    |> render(:"403", %{message: message})
  end

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(ValidationError)
    |> render(:"422", changeset)
  end

  def call(conn, %Ecto.Changeset{valid?: false} = changeset) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(ValidationError)
    |> render(:"422", changeset)
  end

  def call(conn, {:error, json_schema_errors}) when is_list(json_schema_errors) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(ValidationError)
    |> render(:"422", %{schema: json_schema_errors})
  end
end
