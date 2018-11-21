defmodule Scheduler.Worker do
  @moduledoc false

  use Quantum.Scheduler, otp_app: :otp_verification_scheduler

  alias Crontab.CronExpression.Parser
  alias Quantum.Job
  alias Quantum.RunStrategy.Local
  alias Scheduler.Jobs.Deactivator
  alias Scheduler.Jobs.SmsStatusUpdater
  alias Scheduler.Jobs.Terminator

  def create_jobs do
    create_job(&Terminator.run/0, :terminator_schedule)
    create_job(&Deactivator.run/0, :deactivator_schedule)
    create_job(&SmsStatusUpdater.run/0, :sms_status_updater_schedule)
  end

  defp create_job(fun, config_name) do
    config = Confex.fetch_env!(:otp_verification_scheduler, __MODULE__)

    __MODULE__.new_job()
    |> Job.set_overlap(false)
    |> Job.set_schedule(Parser.parse!(config[config_name]))
    |> Job.set_task(fun)
    |> Job.set_run_strategy(%Local{})
    |> __MODULE__.add_job()
  end
end
