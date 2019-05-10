defmodule OtpVerification.Rpc do
  @moduledoc """
  This module contains functions that are called from other pods via RPC.
  """

  alias Core.SMSLog.Schema, as: SMSLog
  alias Core.SMSLogs
  alias Core.Verification.Verification
  alias Core.Verification.Verifications
  alias Core.Verification.VerifiedPhone
  alias OtpVerification.Web.SMSView
  alias OtpVerification.Web.VerificationsView

  @type verification :: %{
          active: boolean(),
          code_expired_at: DateTime,
          id: binary(),
          status: binary()
        }

  @type sms :: %{
          body: binary(),
          id: binary(),
          phone_number: binary(),
          type: binary()
        }

  @type phone_response :: %{
          phone_number: binary()
        }

  @doc """
  Get verification phone by phone number

  ## Examples

      iex> OtpVerification.Rpc.verification_phone("+380960000000")
      {:ok, %{phone_number: "+380960000000"}}
  """
  @spec verification_phone(phone_number :: binary()) :: {:ok, phone_response} | nil
  def verification_phone(phone_number) do
    with %VerifiedPhone{phone_number: phone_number} <- Verifications.get_verified_phone(phone_number) do
      {:ok, VerificationsView.render("phone.json", %{verified_phone: phone_number})}
    end
  end

  @doc """
  Initialize sms by phone number and provider

  ## Examples

      iex> OtpVerification.Rpc.initialize("+380960000000")
      {:ok,
      %{
        active: true,
        code_expired_at: #DateTime<2019-05-02 21:58:51.902086Z>,
        id: "53982ced-ed95-48a9-bab7-78247ec7259f",
        status: "new"
      }}
  """
  @spec initialize(phone_number :: binary(), provider :: binary() | nil) :: {:ok, verification} | {:error, atom}
  def initialize(phone_number, provider \\ nil) do
    with {:ok, %Verification{} = verification} <- Verifications.initialize_verification(phone_number, provider) do
      {:ok, VerificationsView.render("show.json", %{verification: verification})}
    end
  end

  @doc """
  Complete code by phone_number

  ## Examples

      iex> OtpVerification.Rpc.complete("+380960000000", 123456)
      {:ok,
      %{
        active: false,
        code_expired_at: #DateTime<2019-08-07 00:00:00.000000Z>,
        id: "448c7356-1b69-4f4f-be70-d7e558b7cb09",
        status: "verified"
      }}
  """
  @spec complete(phone_number :: binary(), code :: integer) :: {:ok, verification} | {:error, atom} | nil
  def complete(phone_number, code) do
    with {:ok, %Verification{} = verification} <- Verifications.complete(phone_number, code) do
      {:ok, VerificationsView.render("show.json", %{verification: verification})}
    end
  end

  @doc """
  Send sms to phone number with body, type and provider

  ## Examples

      iex> OtpVerification.Rpc.send_sms("+380960000000", "foo", "undefined")
      {:ok,
      %{
        body: "foo",
        id: "08600dea-f366-44e4-ad44-7111368f2209",
        phone_number: "+380960000000",
        type: "undefined"
      }}
  """
  @spec send_sms(phone_number :: binary(), body :: binary(), type :: binary(), provider :: binary()) ::
          {:ok, sms} | {:error, any}
  def send_sms(phone_number, body, type, provider \\ nil) do
    with {:ok, %SMSLog{} = sms} <-
           SMSLogs.save_and_send_sms(phone_number, body, type, provider) do
      {:ok, SMSView.render("show.json", %{sms: sms})}
    end
  end
end
